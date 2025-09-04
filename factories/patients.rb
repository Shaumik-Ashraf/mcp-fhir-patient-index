FactoryBot.define do
  factory :patient do
    initialize_with { Patient.build_random }
  end
end
