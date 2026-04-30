module Agent
  class UpdatePatientTool < ApplicationTool
    tool_name "update_patient"
    description "Update demographic information on an existing patient record in the Master Patient Index."
    input_schema(
      properties: {
        patient_uuid:           { type: "string", description: "UUID of the patient record to update" },
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
      required: [ :patient_uuid ]
    )
    annotations(read_only_hint: false, destructive_hint: false)

    UPDATABLE_FIELDS = %i[
      first_name last_name administrative_gender birth_date email phone_number
      address_line1 address_line2 address_city address_state address_zip_code
      social_security_number passport_number drivers_license_number
    ].freeze

    def self.call(patient_uuid:, server_context:, **params)
      log = AuditLog.create!(
        description: "LLM updated patient record",
        tags: {
          AuditLog::Tag::EVENT => AuditLog::Event::MCP_UPDATE_PATIENT,
          AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP
        },
        encrypted_request: params.merge(patient_uuid:)
      )
      record = PatientRecord.find_by(uuid: patient_uuid)
      result_text = if record.nil?
        "No patient found with UUID #{patient_uuid}."
      else
        updates = params.slice(*UPDATABLE_FIELDS).compact
        if record.update(updates)
          "Updated patient #{record.uuid}:\n\n#{record.to_text}"
        else
          "Failed to update patient due to the following errors: #{record.errors.full_messages.join(', ')}."
        end
      end
      log.update!(encrypted_response: result_text)
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end
  end
end
