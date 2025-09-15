require 'rails_helper'

RSpec.describe "patient_records/edit", type: :view do
  let(:patient) { create(:patient_record) }

  before do
    assign(:patient_record, patient)
  end

  it "renders the edit patient form" do
    render

    assert_select "form[action=?][method=?]", patient_record_path(patient), "post" do
      assert_select "input[name=?]", "patient_record[first_name]"

      assert_select "input[name=?]", "patient_record[last_name]"

      assert_select "input[name=?]", "patient_record[administrative_gender]"

      assert_select "input[name=?]", "patient_record[email]"

      assert_select "input[name=?]", "patient_record[phone_number]"

      assert_select "input[name=?]", "patient_record[address_line1]"

      assert_select "input[name=?]", "patient_record[address_line2]"

      assert_select "input[name=?]", "patient_record[address_city]"

      assert_select "input[name=?]", "patient_record[address_state]"

      assert_select "input[name=?]", "patient_record[address_zip_code]"

      assert_select "input[name=?]", "patient_record[social_security_number]"

      assert_select "input[name=?]", "patient_record[passport_number]"

      assert_select "input[name=?]", "patient_record[drivers_license_number]"
    end
  end
end
