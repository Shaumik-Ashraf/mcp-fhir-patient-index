class PatientRecord < ApplicationRecord
  include ActiveSnapshot

  has_many :patient_joins, dependent: :destroy, inverse_of: :from_patient_record
  has_many :patients, through: :patient_joins, source: :to_patient_record

  has_snapshot_children do
    # Executed in the context of the instance / self

    # Reload record to ensure a clean state
    instance = self.reload

    {
      patient_joins: instance.patient_joins
    }
  end

  enum :administrative_gender, %i[male female other unknown]

  before_create do
    self.uuid = SecureRandom.uuid
  end

  # Takes a patient record and creates other duplicate records
  # but modifies random attributes with typos.
  #
  # @param [PatientRecord] patient_record - original truth
  # @option [Integer] records_to_generate - number of corrupted records to make
  # @option [Float] randomness - value from 0 to 1; 0 for minimal corruption 1 for maximum
  # @return [Array<PatientRecord>] - array of corrupted duplicates
  def self.simulate_corruption(patient_record, records_to_generate: 1, randomness: 0.2)
    raise StandardError, "TODO"
  end
  
  # @param [Hash] attributes - specify certain patient attributes
  # @return [PatientRecord] unsaved instance
  def self.build_random(**attributes)
    self.build(random_attributes.merge(attributes))
  end

  # @param [Hash] attributes - specify certain patient attributes
  # @return [PatientRecord]
  def self.create_random(**attributes)
    self.create(random_attributes.merge(attributes))
  end

  # @param [Hash] attributes - specify certain patient attributes
  # @return [PatientRecord]
  # @raises [ActiveRecord::RecordInvalid]
  def self.create_random!(**attributes)
    patient = self.create_random(**attributes)
    raise ActiveRecord::RecordInvalid unless patient.errors.empty?

    patient
  end

  # @return [Array<Symbol>] - Model attributes from clinical setting and not from code infrastructure
  def self.clinical_attributes
    self.random_attributes.keys
  end

  # @return [Hash] - Patient attributes from clinical setting only (not code infrastructure)
  def clinical_attributes
    attributes.symbolize_keys.slice(*PatientRecord.clinical_attributes)
  end

  # @return [String] - unique active snapshot identifier
  def generate_snapshot_identifier
    "patient_record_snapshot_#{self.uuid}_#{self.snapshots.count}"
  end

  # @return [String] - override URL ID
  def to_param
    uuid
  end

  # @return [Boolean] - true if any name attribute is present
  def name?
    self.first_name.present? || self.last_name.present?
  end

  # @return [Integer]
  def age
    age = DateTime.current.year - self.birth_date.year
    age -= 1 if DateTime.current < self.birth_date + age.years
    age
  end

  # @return [Boolean] - true if any address attribute is present
  def address?
    attributes.keys.select { |a| a.starts_with? "address_" }.any? { |a| self.send(a).present? }
  end

  # @return [FHIR::Patient]
  # @example
  #   PatientRecord.first.to_fhir.to_json # => get FHIR JSON
  #   PatientRecord.first.to_fhir.to_xml  # => get FHIR XML
  def to_fhir
    fhir_patient = FHIR::Patient.new(
      {
        id: self.uuid,
        meta: { lastUpdated: self.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ") }, # FHIR instant type allows omitting fractional seconds
        language: "en-US"
      }
    )

    if self.name?
      fhir_name = FHIR::HumanName.new()
      fhir_name.family = self.last_name if self.last_name.present?
      fhir_name.given << self.first_name if self.first_name.present?

      fhir_patient.name << fhir_name
    end

    fhir_patient.gender = self.administrative_gender
    fhir_patient.birthDate = self.birth_date.strftime("%Y-%m-%d") if self.birth_date

    if self.address?
      fhir_patient.address << FHIR::Address.new(
        {
          line: [ self.address_line1, self.address_line2 ].compact,
          city: self.address_city,
          state: self.address_state,
          postalCode: self.address_zip_code,
          country: "US" # constraint
        }
      )
    end

    fhir_patient.telecom << FHIR::ContactPoint.new({ system: "email", value: self.email }) if self.email.present?
    fhir_patient.telecom << FHIR::ContactPoint.new({ system: "phone", value: self.phone_number }) if self.phone_number.present?

    {
      "DL" => self.drivers_license_number.presence,
      "PPN" => self.passport_number.presence,
      "SS" => self.social_security_number.presence,
      "MR" => self.uuid
    }.each do |code, value|
      fhir_patient.identifier << FHIR::Identifier.new(
        {
          type:
            {
              coding: [
                FHIR::Coding.new(
                  {
                    system: "http://terminology.hl7.org/CodeSystem/v2-0203",
                    code:
                  }
                )
              ]
            },
          value:
        }
      )
    end

    # Additional FHIR attributes should be added here

    # FHIR encourages having a text representation built into resources as a fail safe,
    # although due to the risk of injection attacks I'm not sure how many FHIR vendors support it.
    fhir_patient.text = FHIR::Narrative.new({ status: "generated", div: %Q(<div xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">#{self.to_text}</div>) })
    fhir_patient
  end

  # @return [String] - Natural language plain text representation of patient
  def to_text
    return "Patient data is empty." if self.clinical_attributes.values.none? { |a| a.present? }

    sentences = []
    if self.name?
      sentences << "Patient name is #{[ self.first_name, self.last_name ].join(' ')}"
    end

    if self.birth_date || self.administrative_gender
      sentences << "Patient is #{self.birth_date_gender_to_text}"
    end

    if self.address?
      sentences << "Patient lives at #{self.address_to_text}"
    end

    remaining_attributes = self.clinical_attributes.clone
    remaining_attributes.extract!(:first_name,
                                  :last_name,
                                  :administrative_gender,
                                  :birth_date,
                                  :address_line1,
                                  :address_line2,
                                  :address_city,
                                  :address_state,
                                  :address_zip_code)
    remaining_attributes.each do |key, value|
      if value.to_s.present?
        sentences << "Patient #{key.to_s.humanize(capitalize: false)} is #{value.to_s.humanize(capitalize: false)}"
      end
    end

    sentences.join(". ") + "."
  end

  private

  def self.random_attributes
    {
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      administrative_gender: PatientRecord.administrative_genders.keys.sample,
      birth_date: Faker::Date.birthday(min_age: 18, max_age: 129),
      email: Faker::Internet.email,
      phone_number: Faker::PhoneNumber.phone_number,
      address_line1: Faker::Address.street_address,
      address_line2: Faker::Address.secondary_address,
      address_city: Faker::Address.city,
      address_state: Faker::Address.state,
      address_zip_code: Faker::Address.zip,
      social_security_number: Faker::IdNumber.valid,
      passport_number: Faker::DrivingLicence.usa_driving_licence + Faker::Number.number(digits: 2).to_s,
      drivers_license_number: Faker::DrivingLicence.usa_driving_licence
    }
  end

  # Antiquity text generation in the days of LLMs
  def birth_date_gender_to_text
    phrase = ""
    phrase += self.birth_date_to_text if self.birth_date
    phrase += " " if self.birth_date && self.administrative_gender
    phrase += self.gender_to_text if self.administrative_gender
    phrase
  end

  def birth_date_to_text
    "#{age} y/o"
  end

  def gender_to_text
    if %w[male female].include? self.administrative_gender
      "#{self.administrative_gender}"
    elsif self.administrative_gender.present?
      "of #{self.administrative_gender} gender"
    else
      ""
    end
  end

  def address_to_text
    [ address_line1, address_line2, address_city, address_state, address_zip_code ].map(&:presence).compact.join(", ")
  end
end
