require 'rails_helper'

RSpec.describe PatientJoin, type: :model do
  let(:from_patient) { create(:patient) }
  let(:to_patient) { create(:patient) }

  it "can link two patients" do
    link = create(:patient_join, from: from_patient, to: to_patient)
    expect(from_patient.patient_joins.first&.to_patient_record).to include(to_patient)
  end

  it "can link bidirectionally" do
    link = create(:patient_join, from: from_patient, to: to_patient)
    expect(to_patient.linked_patient_records).to include(link) # TODO: rename linked_patient_records
  end
end
