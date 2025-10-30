require 'rails_helper'

RSpec.describe "Settings", type: :request do
  let!(:setting) do
    Setting.find_or_create_by!(key: 'last_four_ssn') do |s|
      s.value = true
      s.description = 'Only display the last four digits of an SSN'
    end
  end

  describe "GET /settings" do
    it "returns http success" do
      get settings_path
      expect(response).to have_http_status(:success)
    end

    it "displays settings page" do
      get settings_path
      expect(response.body).to include('Settings')
      expect(response.body).to include('Last four ssn')
    end
  end

  describe "PATCH /settings/:id" do
    context "with valid boolean toggle" do
      it "updates setting to false" do
        patch setting_path(setting), params: { setting: { value: false } }
        expect(setting.reload.value).to eq(false)
        expect(response).to redirect_to(settings_path)
      end

      it "updates setting to true" do
        setting.update!(value: false)
        patch setting_path(setting), params: { setting: { value: true } }
        expect(setting.reload.value).to eq(true)
        expect(response).to redirect_to(settings_path)
      end
    end

    context "with nonexistent setting" do
      it "redirects with error message" do
        patch setting_path(id: 99999), params: { setting: { value: false } }
        expect(response).to redirect_to(settings_path)
        expect(flash[:alert]).to eq('Setting not found.')
      end
    end
  end
end
