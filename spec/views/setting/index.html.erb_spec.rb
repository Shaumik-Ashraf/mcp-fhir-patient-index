require 'rails_helper'

RSpec.describe "setting/index.html.erb", type: :view do
  it "displays all settings" do
    assign(:settings, [
             Setting.create!(key: "mock_setting")
           ])

    render template: "settings/index"

    expect(rendered).to match /mock[-_ ]setting/i
  end
end
