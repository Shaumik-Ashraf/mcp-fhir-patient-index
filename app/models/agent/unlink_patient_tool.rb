module Agent
  class UnlinkPatientTool < ApplicationTool
    tool_name "unlink_patient"
    description "Remove all identity links for a patient record, fully isolating it from any linked identity group."
    input_schema(
      properties: {
        patient_uuid: { type: "string", description: "UUID of the patient record to unlink from its identity group" }
      },
      required: [ :patient_uuid ]
    )
    annotations(read_only_hint: false, destructive_hint: true)

    def self.call(patient_uuid:, server_context:)
      log = AuditLog.create!(
        description: "LLM unlinked patient record from identity group",
        tags: {
          AuditLog::Tag::EVENT => AuditLog::Event::MCP_DELINK_PATIENT,
          AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP
        },
        encrypted_request: { patient_uuid: }
      )
      record = PatientRecord.find_by(uuid: patient_uuid)
      result_text = if record.nil?
        "No patient found with UUID #{patient_uuid}."
      else
        count = record.patient_joins.count + record.reverse_patient_joins.count
        record.patient_joins.destroy_all
        record.reverse_patient_joins.destroy_all
        "Unlinked patient #{patient_uuid}: removed #{count} link(s)."
      end
      log.update!(encrypted_response: result_text)
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end
  end
end
