# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create settings
Setting.find_or_create_by!(key: "last_four_ssn") do |setting|
  setting.description = "Only display the last four digits of an SSN"
  setting.value = true
end

Setting.find_or_create_by!(key: "auto_match_threshold") do |setting|
  setting.description = "Minimum score (0.0–1.0) for the matching engine to consider two patient records the same identity"
  setting.value = 0.7
end

if ENV["MOCKUP_PATIENTS"]&.casecmp? "TRUE"
  # Seed 3 random "real" patients, each with 2 corrupted duplicate records
  3.times do
    patient = PatientRecord.create_random!
    PatientRecord.simulate_corruption(patient, records_to_generate: 2, randomness: 0.5)
  end
  puts "Seeded 3 mock patients with 2 corrupted records each"
end
