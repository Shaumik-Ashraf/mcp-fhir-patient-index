require 'rails_helper'

RSpec.describe "patients/index", type: :view do
  before(:each) do
    assign(:patients, create_list(:patient, 2))
  end

  it "renders a list of patients" do
    render
    cell_selector = 'div>p'
    visible_attributes = %w[first_name last_name email phone_number] # TODO: set visible attrs
    Patient.all.each do |patient|
      visible_attributes.each do |attribute|
        assert_select cell_selector, text: Regexp.new(patient.send(attribute))
      end
    end
  end
end
