require 'rails_helper'

RSpec.describe Setting, type: :model do
  before do
    described_class.find_or_create_by!(key: 'dummy') do |setting|
      setting.value = true
    end
  end

  it "can get settings with brackets" do
    expect(described_class[:dummy]).to be true
  end

  it "can set settings with brackets" do
    expect(described_class[:dummy]=false).to be false
  end

  it "can raise error for non-existing settings" do
    expect { described_class[:not_found] }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
