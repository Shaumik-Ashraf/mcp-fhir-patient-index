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
        expect(setting.reload.value).to eq(false)
      end

      it 'redirects to settings index with success notice' do
        patch :update, params: { id: setting.id, setting: { value: false } }
        expect(response).to redirect_to(settings_path)
        expect(flash[:notice]).to eq('Setting updated successfully.')
      end
    end

    context 'with invalid setting id' do
      it 'redirects to settings index with error alert' do
        patch :update, params: { id: 99999, setting: { value: false } }
        expect(response).to redirect_to(settings_path)
        expect(flash[:alert]).to eq('Setting not found.')
      end
    end

    context 'when update fails' do
      before do
        allow_any_instance_of(Setting).to receive(:update).and_return(false)
      end

      it 'redirects with failure alert' do
        patch :update, params: { id: setting.id, setting: { value: false } }
        expect(response).to redirect_to(settings_path)
        expect(flash[:alert]).to eq('Failed to update setting.')
      end
    end
  end
end
