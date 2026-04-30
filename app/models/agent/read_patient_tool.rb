module Agent
  class ReadPatientTool < ApplicationTool
    tool_name "read_patient"
    description "Read a single patient record from the Master Patient Index by UUID."
    input_schema(
      properties: {
        patient_uuid: { type: "string", description: "UUID of the patient record to read" }
      },
      required: [ :patient_uuid ]
    )
    annotations(read_only_hint: true, destructive_hint: false)

    def self.call(patient_uuid:, server_context:)
      log = AuditLog.create!(
        description: "LLM read patient record",
        tags: {
          AuditLog::Tag::EVENT => AuditLog::Event::MCP_READ_PATIENT,
          AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP
        },
        encrypted_request: { patient_uuid: }
      )
      record = PatientRecord.find_by(uuid: patient_uuid)
      result_text = if record
        record.to_text
      else
        "No patient found with UUID #{patient_uuid}."
      end
      log.update!(encrypted_response: result_text)
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end
  end
end
