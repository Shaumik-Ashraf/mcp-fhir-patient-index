class Patient < ApplicationRecord
  enum :administrative_gender, %i[male female other unknown]

  before_create do
    self.uuid = SecureRandom.uuid
  end

  # @param [Hash] attributes - specify certain patient attributes
  # @return [Patient] unsaved instance
  def self.build_random(**attributes)
    self.build(random_attributes.merge(attributes))
  end

  # @param [Hash] attributes - specify certain patient attributes
  # @return [Patient]
  def self.create_random(**attributes)
    self.create(random_attributes.merge(attributes))
  end

  # @param [Hash] attributes - specify certain patient attributes
  # @return [Patient]
  # @raises [ActiveRecord::RecordInvalid]
  def self.create_random!(**attributes)
    patient = self.create_random(attributes)
    raise ActiveRecord::RecordInvalid unless patient.errors.empty?

    patient
  end

  # @return [Array<Symbol>] - Model attributes from clinical setting and not from code infrastructure
  def self.clinical_attributes
    self.random_attributes.keys
  end

  # @return [Hash] - Patient attributes from clinical setting only (not code infrastructure)
  def clinical_attributes
    attributes.symbolize_keys.slice(*Patient.clinical_attributes)
  end

  # @return [String] - override URL ID
  def to_param
    uuid
  end

  # @return [FHIR::Patient]
  # @example
  #   Patient.first.to_fhir.to_json # => get FHIR JSON
  #   Patient.first.to_fhir.to_xml  # => get FHIR XML
  def to_fhir
    FHIR::Patient.new(
      {
        name: FHIR::HumanName.new(
          {
            family: self.last_name,
            given: [ self.first_name ]
          }
        ),
        gender: self.administrative_gender,
        birthDate: self.birth_date.strftime("%Y-%m-%d"),
        address: [FHIR::Address.new(
          {
            line: [ self.address_line1, self.address_line2 ].compact,
            city: self.address_city,
            state: self.address_state,
            postalCode: self.address_zip_code,
            country: "US" # constraint
          }
        )],
        telecom: [
          FHIR::ContactPoint.new({ system: "email", value: self.email }),
          FHIR::ContactPoint.new({ system: "phone", value: self.phone_number })
        ],
        identifier: [
          FHIR::Identifier.new(
            {
              type:
                {
                  coding:
                    [
                      FHIR::Coding.new(
                        {
                          system: "http://terminology.hl7.org/CodeSystem/v2-0203",
                          code: "DL" # DL # PPN # SS # MR
                        }
                      )
                    ]
                },
              value: self.drivers_license_number
            }
          ),
          # TODO: passport number (PPN) and social (SS) and uuid (MR)
        ]
      }
    )
  end


  private

  def self.random_attributes
    {
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      administrative_gender: Patient.administrative_genders.keys.sample,
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
end
