require 'rails_helper'

RSpec.describe PatientJoin, type: :model do
  let(:from_patient) { create(:patient) }
  let(:to_patient) { create(:patient) }

  it "can link two patients" do
    link = create(:patient_join, from: from_patient, to: to_patient)
    expect(from_patient.patient_joins.first&.to_patient_record).to eq(to_patient)
  end

  # TODO: rework patient join into a network
  # it "can link bidirectionally" do
  #   link = create(:patient_join, from: from_patient, to: to_patient)
  #   expect(to_patient.linked_patient_records).to include(link)
  # end
end
