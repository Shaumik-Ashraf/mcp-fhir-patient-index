require 'rails_helper'

RSpec.describe "patients/index", type: :view do
  before do
    assign(:patients, create_list(:patient, 2))
  end

  it "renders a list of patients with uuids" do
    render

    Patient.all.each do |patient|
      expect(rendered).to match patient.uuid
    end
  end
end
