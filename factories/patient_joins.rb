FactoryBot.define do
  factory :patient_join do
    transient do
      from { create(:patient) }
      to { create(:patient) }
    end
    from_patient_record { from }
    to_patient_record { to }
    qualifier { :has_same_identity_as }
    notes { Faker::Boolean.boolean ? Faker::Lorem.sentence : nil }
  end
end
