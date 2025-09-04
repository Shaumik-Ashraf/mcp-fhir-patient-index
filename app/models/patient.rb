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
    attributes.slice(Patient.clinical_attributes)
  end

  # @return [String] - override URL ID
  def to_param
    uuid
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
