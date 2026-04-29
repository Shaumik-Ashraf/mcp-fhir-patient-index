module Agent
  class LinkPatientsTool < ApplicationTool
    tool_name "link_patients"
    description "Link two patient records as having the same identity (has_same_identity_as). The link is bidirectional."
    input_schema(
      properties: {
        patient_uuid_1: { type: "string", description: "UUID of the first patient record" },
        patient_uuid_2: { type: "string", description: "UUID of the second patient record" },
        notes:          { type: "string", description: "Optional notes about why these records were linked" }
      },
      required: %w[patient_uuid_1 patient_uuid_2]
    )
    annotations(read_only_hint: false, destructive_hint: true)

    def self.call(patient_uuid_1:, patient_uuid_2:, notes: nil, server_context:)
      log = AuditLog.create!(
        description: "LLM linked patient records",
        tags: {
          AuditLog::Tag::EVENT => AuditLog::Event::MCP_LINK_PATIENT,
          AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP
        },
        encrypted_request: { patient_uuid_1:, patient_uuid_2:, notes: }
      )
      patient1 = PatientRecord.find_by!(uuid: patient_uuid_1)
      patient2 = PatientRecord.find_by!(uuid: patient_uuid_2)
      PatientJoin.create!(
        from_patient_record: patient1,
        to_patient_record: patient2,
        qualifier: :has_same_identity_as,
        notes:
      )
      result_text = "Linked patients:\n- #{patient1.uuid} (#{patient1.to_text.lines.first.chomp})\n- #{patient2.uuid} (#{patient2.to_text.lines.first.chomp})"
      log.update!(encrypted_response: result_text)
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end
  end
end
