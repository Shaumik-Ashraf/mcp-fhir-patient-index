require 'rails_helper'

RSpec.describe "patients/edit", type: :view do
  let(:patient) { create(:patient) }

  before(:each) do
    assign(:patient, patient)
  end

  it "renders the edit patient form" do
    render

    assert_select "form[action=?][method=?]", patient_path(patient), "post" do
      assert_select "input[name=?]", "patient[first_name]"

      assert_select "input[name=?]", "patient[last_name]"

      assert_select "input[name=?]", "patient[administrative_gender]"

      assert_select "input[name=?]", "patient[email]"

      assert_select "input[name=?]", "patient[phone_number]"

      assert_select "input[name=?]", "patient[address_line1]"

      assert_select "input[name=?]", "patient[address_line2]"

      assert_select "input[name=?]", "patient[address_city]"

      assert_select "input[name=?]", "patient[address_state]"

      assert_select "input[name=?]", "patient[address_zip_code]"

      assert_select "input[name=?]", "patient[social_security_number]"

      assert_select "input[name=?]", "patient[passport_number]"

      assert_select "input[name=?]", "patient[drivers_license_number]"
    end
  end
end
