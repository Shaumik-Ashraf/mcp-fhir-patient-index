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

# Seed 10 random patients with full data
10.times do
  PatientRecord.create_random!
end
