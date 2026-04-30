module Agent
  class AutomatchPatientsTool < ApplicationTool
    tool_name "automatch_patients"
    description "Run the patient identity matching engine to automatically link probable duplicate records. " \
                "If patient_uuid is provided, finds matches only for that patient. Otherwise runs a global match over all patients."
    input_schema(
      properties: {
        patient_uuid: { type: "string", description: "Optional UUID to scope matching to a single patient" }
      }
    )
    annotations(read_only_hint: false, destructive_hint: false)

    def self.call(patient_uuid: nil, server_context:)
      log = AuditLog.create!(
        description: "LLM ran patient record auto-matching",
        tags: {
          AuditLog::Tag::EVENT => AuditLog::Event::MCP_AUTOMATCH,
          AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP
        },
        encrypted_request: { patient_uuid: }
      )
      result_text = if patient_uuid.present?
        scoped_match(patient_uuid)
      else
        global_match
      end
      log.update!(encrypted_response: result_text)
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end

    def self.scoped_match(patient_uuid)
      target = PatientRecord.find_by(uuid: patient_uuid)
      return "No patient found with UUID #{patient_uuid}." if target.nil?

      threshold = Setting[:auto_match_threshold].to_f
      engine    = MatchingEngine.new
      target_input = PatientMatchInput.from_patient_record(target)
      group_map = PatientGroup.index_by_patient_record_id

      matched = []
      PatientRecord.where.not(id: target.id).find_each do |other|
        next if PatientGroup.already_linked?(target.id, other.id, group_map: group_map)
        next unless engine.match?(target_input, PatientMatchInput.from_patient_record(other), threshold: threshold)

        PatientJoin.create!(
          from_patient_record: target,
          to_patient_record: other,
          qualifier: :has_same_identity_as
        )
        matched << other
      end

      if matched.empty?
        "No new matches found for patient #{patient_uuid}."
      else
        lines = matched.map { |r| "- #{r.uuid} (#{r.to_text.lines.first.chomp})" }
        "Linked patient #{patient_uuid} to #{matched.size} match(es):\n#{lines.join("\n")}"
      end
    end
    private_class_method :scoped_match

    def self.global_match
      threshold = Setting[:auto_match_threshold].to_f
      engine    = MatchingEngine.new
      records   = PatientRecord.all.to_a
      group_map = PatientGroup.index_by_patient_record_id

      records.each { |r| group_map[r.id] ||= -r.id }

      joins_created = 0
      records.combination(2) do |r1, r2|
        next if PatientGroup.already_linked?(r1.id, r2.id, group_map: group_map)
        next unless engine.match?(
          PatientMatchInput.from_patient_record(r1),
          PatientMatchInput.from_patient_record(r2),
          threshold: threshold
        )

        PatientJoin.create!(
          from_patient_record: r1,
          to_patient_record: r2,
          qualifier: :has_same_identity_as
        )
        joins_created += 1

        old_group = group_map[r2.id]
        new_group = group_map[r1.id]
        group_map.transform_values! { |g| g == old_group ? new_group : g }
      end

      "Auto-match complete: #{joins_created} new link(s) created."
    end
    private_class_method :global_match
  end
end
