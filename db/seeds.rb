# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed 10 random patients with full data
10.times do
  Patient.create!(
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
  )
end
