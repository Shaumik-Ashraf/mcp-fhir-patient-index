require 'rails_helper'

RSpec.describe "patient_records/index", type: :view do
  before do
    assign(:patient_records, create_list(:patient, 2))
  end

  it "renders a list of patients with uuids" do
    render

    PatientRecord.all.each do |patient|
      expect(rendered).to match patient.uuid
    end
  end
end
