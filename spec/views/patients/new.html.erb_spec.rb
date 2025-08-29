require 'rails_helper'

RSpec.describe "patients/new", type: :view do
  before(:each) do
    assign(:patient, Patient.new(
      uuid: "MyString",
      first_name: "MyString",
      last_name: "MyString",
      administrative_gender: 1,
      email: "MyString",
      phone_number: "MyString",
      social_security_number: "MyString",
      address_line1: "MyString",
      address_line2: "MyString",
      address_city: "MyString",
      address_state: "MyString",
      address_zip_code: "MyString",
      social_security_number: "MyString",
      passport_number: "MyString",
      drivers_license_number: "MyString"
    ))
  end

  it "renders new patient form" do
    render

    assert_select "form[action=?][method=?]", patients_path, "post" do

      assert_select "input[name=?]", "patient[uuid]"

      assert_select "input[name=?]", "patient[first_name]"

      assert_select "input[name=?]", "patient[last_name]"

      assert_select "input[name=?]", "patient[administrative_gender]"

      assert_select "input[name=?]", "patient[email]"

      assert_select "input[name=?]", "patient[phone_number]"

      assert_select "input[name=?]", "patient[social_security_number]"

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
