require 'rails_helper'

RSpec.describe Patient, type: :model do
  let(:patient) { create(:patient) }

  it "can instantiate random patient" do
    expect(patient).not_to be_nil
    expect(patient).to be_instance_of Patient
  end
end
