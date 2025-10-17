FactoryBot.define do
  factory :patient_join do
    from_patient_record { nil }
    to_patient_record { nil }
    qualifier { 1 }
    notes { "MyText" }
  end
end
