require 'rails_helper'

RSpec.describe "patients/index", type: :view do
  before(:each) do
    assign(:patients, [
      Patient.create!(
        uuid: "Uuid",
        first_name: "First Name",
        last_name: "Last Name",
        administrative_gender: 2,
        email: "Email",
        phone_number: "Phone Number",
        social_security_number: "Social Security Number",
        address_line1: "Address Line1",
        address_line2: "Address Line2",
        address_city: "Address City",
        address_state: "Address State",
        address_zip_code: "Address Zip Code",
        social_security_number: "Social Security Number",
        passport_number: "Passport Number",
        drivers_license_number: "Drivers License Number"
      ),
      Patient.create!(
        uuid: "Uuid",
        first_name: "First Name",
        last_name: "Last Name",
        administrative_gender: 2,
        email: "Email",
        phone_number: "Phone Number",
        social_security_number: "Social Security Number",
        address_line1: "Address Line1",
        address_line2: "Address Line2",
        address_city: "Address City",
        address_state: "Address State",
        address_zip_code: "Address Zip Code",
        social_security_number: "Social Security Number",
        passport_number: "Passport Number",
        drivers_license_number: "Drivers License Number"
      )
    ])
  end

  it "renders a list of patients" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Uuid".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("First Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Last Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Email".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Phone Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Social Security Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Address Line1".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Address Line2".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Address City".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Address State".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Address Zip Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Social Security Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Passport Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Drivers License Number".to_s), count: 2
  end
end
