class SettingsController < ApplicationController
  before_action :settings_title

  def index
    @settings = Setting.all.order(:key)
  end

  def update
    setting = Setting.find(params[:id])

    if setting.update(setting_params)
      redirect_to settings_path, notice: "Setting updated successfully."
    else
      redirect_to settings_path, alert: "Failed to update setting."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to settings_path, alert: "Setting not found."
  end

  private

  def settings_title
    set_title "Settings"
  end

  def setting_params
    permitted = params.require(:setting).permit(:value)
    # Convert string boolean values to actual booleans - currently all settings are boolean
    permitted[:value] = ActiveModel::Type::Boolean.new.cast(permitted[:value]) if permitted[:value].is_a?(String)
    permitted
  end
end
