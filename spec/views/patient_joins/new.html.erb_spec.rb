require 'rails_helper'

RSpec.describe "patient_joins/new", type: :view do
  let(:patient_records) do
    [
      create(:patient, first_name: "John", last_name: "Doe"),
      create(:patient, first_name: "Jane", last_name: "Smith")
    ]
  end

  before do
    assign(:patient_records, patient_records)
  end

  it "renders new patient join selection form" do
    render

    assert_select "form[action=?][method=?]", compare_patient_joins_path, "get" do
      assert_select "select#patient_1_uuid[name=?]", "patient_1_uuid"
      assert_select "select#patient_2_uuid[name=?]", "patient_2_uuid"
      assert_select "input[type=submit][value=?]", "Compare Patient Records"
    end
  end

  it "displays all patient records in the dropdowns" do
    render

    patient_records.each do |patient|
      assert_select "select#patient_1_uuid option", text: /#{patient.first_name} #{patient.last_name}/
      assert_select "select#patient_2_uuid option", text: /#{patient.first_name} #{patient.last_name}/
    end
  end
end
