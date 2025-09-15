require 'rails_helper'

RSpec.describe "/fhir/r4/Patient/:uuid", type: :request do
  before do
    create(:patient, first_name: "PATIENT_READ_TEST")
  end

  let(:patient) { PatientRecord.find_by!(first_name: "PATIENT_READ_TEST") }

  it "returns 200 ok" do
    get fhir_r4_patient_url(patient)
    expect(response).to be_successful
  end

  it "returns a FHIR Patient" do
    get fhir_r4_patient_url(patient)
    expect(FHIR.from_contents(response.body)).to be_instance_of FHIR::Patient
  end

  it "returns identical FHIR logical id" do
    get fhir_r4_patient_url(patient)
    expect(FHIR.from_contents(response.body).id).to eq patient.uuid
  end
end
