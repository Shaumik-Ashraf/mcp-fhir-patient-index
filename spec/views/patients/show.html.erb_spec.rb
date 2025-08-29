require 'rails_helper'

RSpec.describe "patients/show", type: :view do
  let(:patient) { create(:patient) }
  
  before(:each) do
    assign(:patient, patient
=begin
    Patient.create!(
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
=end
    ))
  end

  it "renders attributes in <p>" do
    render
    # TODO: hard code realistic attributes above and assert them below
    expect(rendered).to match(/First Name/)
    expect(rendered).to match(/Last Name/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/Phone Number/)
    expect(rendered).to match(/Social Security Number/)
    expect(rendered).to match(/Address Line1/)
    expect(rendered).to match(/Address Line2/)
    expect(rendered).to match(/Address City/)
    expect(rendered).to match(/Address State/)
    expect(rendered).to match(/Address Zip Code/)
    expect(rendered).to match(/Social Security Number/)
    expect(rendered).to match(/Passport Number/)
    expect(rendered).to match(/Drivers License Number/)
  end
end
