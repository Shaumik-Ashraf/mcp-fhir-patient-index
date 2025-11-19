module ApplicationHelper
  # Formats SSN based on the last_four_ssn setting
  # @param ssn [String, nil]
  # @return [String] Formatted SSN or empty string if nil
  def format_ssn(ssn)
    return "" if ssn.blank?

    # Check if setting exists and is enabled
    mask_ssn = Setting[:last_four_ssn] rescue false

    if mask_ssn
      # Return masked SSN showing only last 4 digits
      "***-**-#{ssn.last(4)}"
    else
      # Return full SSN
      ssn
    end
  end

  # Displays value or "Not provided" message if blank
  # @param value [String, nil]
  # @param message [String] Custom message to display when value is blank
  # @return [String, ActiveSupport::SafeBuffer] Value or italicized muted message
  def display_or_blank(value, message = "Not provided")
    value.present? ? value : content_tag(:em, message, class: "text-muted")
  end
end
