require 'rails_helper'

RSpec.describe PatientJoin, type: :model do
  let(:from_patient) { create(:patient) }
  let(:to_patient) { create(:patient) }

  it "can link two patients" do
    link = create(:patient_join, from: from_patient, to: to_patient)
    expect(from_patient.patients).to include(to_patient)
  end
end
