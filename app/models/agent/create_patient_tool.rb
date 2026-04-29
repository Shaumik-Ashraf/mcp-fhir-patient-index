module Agent
  class CreatePatientTool < ApplicationTool
    tool_name "create_patient"
    description "Create a new patient record in the Master Patient Index."
    input_schema(
      properties: {
        first_name:             { type: "string" },
        last_name:              { type: "string" },
        administrative_gender:  { type: "string", enum: %w[male female other unknown] },
        birth_date:             { type: "string", description: "ISO 8601 date, e.g. 1990-01-15" },
        email:                  { type: "string" },
        phone_number:           { type: "string" },
        address_line1:          { type: "string" },
        address_line2:          { type: "string" },
        address_city:           { type: "string" },
        address_state:          { type: "string" },
        address_zip_code:       { type: "string" },
        social_security_number: { type: "string" },
        passport_number:        { type: "string" },
        drivers_license_number: { type: "string" }
      },
      required: [ :last_name ] # At least one required
    )
    annotations(
      read_only_hint: false,
      destructive_hint: false
    )

    def self.call(server_context:, **params)
      log = AuditLog.create!(
        description: "LLM created patient record",
        tags: {
          AuditLog::Tag::EVENT => AuditLog::Event::MCP_CREATE_PATIENT,
          AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP
        },
        encrypted_request: params
      )
      patient = PatientRecord.new(params)
      if patient.save
        result_text = "Created patient #{patient.uuid}:\n\n#{patient.to_text}"
      else
        result_text = "Failed to create patient due to the following errors: #{patient.errors.full_messages.join(',')}."
      end
      log.update!(encrypted_response: result_text)
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end
  end
end
