require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the SettingHelper. For example:
#
# describe SettingHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe SettingHelper, type: :helper do
  let(:setting) { Setting.find_or_create_by!(key: 'last_four_ssn') }

  describe "#display_key" do
    it "humanizes setting name from key" do
      expect(helper.display_key(setting)).to eq("Last Four SSN")
    end
  end
end
