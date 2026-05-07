module Agent
  class FindPatientTool < ApplicationTool
    tool_name "find_patient"
    description "Find the first patient record matching the given attribute filters. " \
                "Only the first match is returned; other matching records may be excluded. " \
                "Use `list_patients` to retrieve all matches. " \
                "No attribute (including SSN, passport, or driver's license) is guaranteed unique."
    input_schema(
      properties: {
        first_name:             { type: "string", description: "Filter by first name (case-insensitive substring)" },
        last_name:              { type: "string", description: "Filter by last name (case-insensitive substring)" },
        birth_date:             { type: "string", description: "Filter by birth date (case-insensitive substring, ISO 8601)" },
        administrative_gender:  { type: "string", enum: %w[male female other unknown], description: "Filter by exact gender" },
        email:                  { type: "string", description: "Filter by email (case-insensitive substring)" },
        phone_number:           { type: "string", description: "Filter by phone number (case-insensitive substring)" },
        address_city:           { type: "string", description: "Filter by city (case-insensitive substring)" },
        address_state:          { type: "string", description: "Filter by state (case-insensitive substring)" },
        address_zip_code:       { type: "string", description: "Filter by zip code (case-insensitive substring)" },
        social_security_number: { type: "string", description: "Filter by SSN (case-insensitive substring, not unique)" },
        passport_number:        { type: "string", description: "Filter by passport number (case-insensitive substring, not unique)" },
        drivers_license_number: { type: "string", description: "Filter by driver's license number (case-insensitive substring, not unique)" }
      }
    )
    annotations(read_only_hint: true, destructive_hint: false)

    def self.call(server_context:, **params)
      filter_keys = PatientFilter::TEXT_FILTER_FIELDS.map(&:to_sym) + [ :administrative_gender ]
      filter_params = params.slice(*filter_keys)
      if filter_params.values.none?(&:present?)
        result_text = "At least one filter attribute is required. Provide a value for one or more fields such as last_name, email, or birth_date."
        return MCP::Tool::Response.new([ { type: "text", text: result_text } ])
      end

      log = AuditLog.create!(
        description: "LLM found patient record",
        tags: {
          AuditLog::Tag::EVENT => AuditLog::Event::MCP_FIND_PATIENT,
          AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP
        },
        encrypted_request: filter_params
      )
      record = PatientFilter.apply(PatientRecord.all, filter_params).first
      result_text = record ? record.to_text : "No patient found matching the given criteria."
      log.update!(encrypted_response: result_text)
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end
  end
end
