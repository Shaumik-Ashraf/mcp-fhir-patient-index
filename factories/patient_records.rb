FactoryBot.define do
  factory :patient_record, aliases: %i[patient] do
    initialize_with { PatientRecord.build_random }
  end
end
