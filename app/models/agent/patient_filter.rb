module Agent
  module PatientFilter
    TEXT_FILTER_FIELDS = %w[
      first_name last_name birth_date email phone_number
      address_city address_state address_zip_code
      social_security_number passport_number drivers_license_number
    ].freeze

    def self.apply(scope, params)
      TEXT_FILTER_FIELDS.each do |field|
        val = params[field.to_sym]
        scope = scope.where("LOWER(#{field}) LIKE ?", "%#{val.to_s.downcase}%") if val.present?
      end
      administrative_gender = params[:administrative_gender]
      scope = scope.where(administrative_gender:) if administrative_gender.present?
      scope
    end
  end
end
