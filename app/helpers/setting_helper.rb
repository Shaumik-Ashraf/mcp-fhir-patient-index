module SettingHelper
  # @example
  #   <%= display_key Setting.find_by(key: "last_four_ssn" %>
  #   Last Four SSN
  def display_key(setting)
    setting.key.split("_").map(&:humanize).join(" ")
  end
end
