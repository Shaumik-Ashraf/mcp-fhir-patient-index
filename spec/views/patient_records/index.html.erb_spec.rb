require 'rails_helper'

RSpec.describe "patient_records/index", type: :view do
  before do
    assign(:patient_records, create_list(:patient, 2))
    render
  end

  it "renders the patient grid container" do
    expect(rendered).to have_selector "#patient-grid"
  end

  it "renders a link to create a new patient" do
    expect(rendered).to have_link "New Patient"
  end

  it "does not inline patient data" do
    PatientRecord.all.each do |patient|
      expect(rendered).not_to match patient.uuid
    end
  end
end
