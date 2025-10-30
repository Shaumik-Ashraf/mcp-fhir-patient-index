require 'rails_helper'

RSpec.describe SettingsController, type: :controller do
  let!(:setting) do
    Setting.find_or_create_by!(key: 'last_four_ssn') do |setting|
      setting.value = true
      setting.description = 'Test setting'
    end
  end

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    context 'with valid params' do
      it 'updates the setting value' do
        patch :update, params: { id: setting.id, setting: { value: false } }
        expect(setting.reload.value).to be(false)
      end

      it 'redirects to settings index' do
        patch :update, params: { id: setting.id, setting: { value: false } }
        expect(response).to redirect_to(settings_path)
      end
    end

    context 'with invalid setting id' do
      it 'redirects to settings index' do
        patch :update, params: { id: 99999, setting: { value: false } }
        expect(response).to redirect_to(settings_path)
      end
    end

    context 'when update fails' do
      before do
        allow_any_instance_of(Setting).to receive(:update).and_return(false) # rubocop:disable RSpec/AnyInstance
      end

      it 'redirects' do
        patch :update, params: { id: setting.id, setting: { value: false } }
        expect(response).to redirect_to(settings_path)
      end
    end
  end
end
