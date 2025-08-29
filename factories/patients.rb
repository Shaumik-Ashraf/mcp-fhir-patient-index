FactoryBot.define do
  factory :patient do
    administrative_gender { Patient.administrative_genders.keys.sample }
    first_name do
      case administrative_gender
      when :male
        Faker::Name.male_first_name
      when :female
        Faker::Name.female_first_name
      else
        Faker::Name.first_name
      end
    end
    last_name { Faker::Name.last_name }
    birth_date { Faker::Date.between(from: 100.years.ago, to: Date.today) }
    email { Faker::Internet.email }
    phone_number { Faker::PhoneNumber.phone_number }
    address_line1 { Faker::Address.street_address }
    address_line2 { Random.rand(2) == 1 ? Faker::Address.secondary_address : nil }
    address_city { Faker::Address.city }
    address_state { Faker::Address.state }
    address_zip_code { Faker::Address.zip }
    social_security_number { Faker::IdNumber.valid }
    passport_number { Faker::DrivingLicence.usa_driving_licence + Faker::Number.number(digits: 2).to_s }
    drivers_license_number { Faker::DrivingLicence.usa_driving_licence  }
  end
end
