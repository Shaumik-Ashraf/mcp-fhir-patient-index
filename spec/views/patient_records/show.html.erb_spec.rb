require 'rails_helper'

RSpec.describe "patient_records/show", type: :view do
  let(:patient) { create(:patient) }

  before do
    assign(:patient_record, PatientRecord.create!(
      first_name: "First Name",
      last_name: "Last Name",
      administrative_gender: 2,
      email: "Email@test.example.com",
      phone_number: "1234567890",
      address_line1: "123 Main St",
      address_line2: "Apt 4",
      address_city: "New York",
      address_state: "NY",
      address_zip_code: "55555",
      social_security_number: "000-00-0000",
      passport_number: "P88888888",
      drivers_license_number: "D7777777"
    ))
  end

  # TODO: redo spec when views are improved
  # rubocop:disable RSpec/MultipleExpectations
  it "renders attributes" do
    render

    expect(rendered).to match(/First Name/)
    expect(rendered).to match(/Last Name/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Email@test\.example\.com/)
    expect(rendered).to match(/1234567890/)
    expect(rendered).to match(/123 Main St/)
    expect(rendered).to match(/Apt 4/)
    expect(rendered).to match(/New York/)
    expect(rendered).to match(/NY/)
    expect(rendered).to match(/55555/)
    expect(rendered).to match(/000-00-0000/)
    expect(rendered).to match(/P88888888/)
    expect(rendered).to match(/D7777777/)
  end
  # rubocop:enable RSpec/MultipleExpectations
end
