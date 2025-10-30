module SettingHelper
  # @example
  #   <%= display_key setting %>
  #   Last Four SSN
  def display_key(setting)
    setting.key.split("_").map(&:humanize).join(" ")
  end
end
