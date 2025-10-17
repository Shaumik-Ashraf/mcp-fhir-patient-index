require 'rails_helper'

RSpec.describe PatientJoin, type: :model do
  let(:from) { create(:patient) }
  let(:to) { create(:patient) }

  it "can link two patients" do
    link = create(:patient_join, from:, to:)
    expect(patient1.patients).to include(patient2)
  end
end
