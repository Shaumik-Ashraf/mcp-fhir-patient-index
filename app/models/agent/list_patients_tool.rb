module Agent
  class ListPatientsTool < ApplicationTool
    SORTABLE_FIELDS = %w[first_name last_name birth_date created_at updated_at].freeze
    TEXT_FILTER_FIELDS = %w[
      first_name last_name birth_date email phone_number
      address_city address_state address_zip_code
      social_security_number passport_number drivers_license_number
    ].freeze

    tool_name "list_patients"
    description "List patient records from the Master Patient Index with optional sorting, limiting, and filtering on any field."
    input_schema(
      properties: {
        limit:                  { type: "integer", description: "Maximum number of records to return (default: 20)" },
        sort_by:                { type: "string", enum: SORTABLE_FIELDS, description: "Field to sort by (default: last_name)" },
        sort_direction:         { type: "string", enum: %w[asc desc], description: "Sort direction (default: asc)" },
        first_name:             { type: "string", description: "Filter by first name (case-insensitive substring)" },
        last_name:              { type: "string", description: "Filter by last name (case-insensitive substring)" },
        birth_date:             { type: "string", description: "Filter by birth date (case-insensitive substring, ISO 8601)" },
        administrative_gender:  { type: "string", enum: %w[male female other unknown], description: "Filter by exact gender" },
        email:                  { type: "string", description: "Filter by email (case-insensitive substring)" },
        phone_number:           { type: "string", description: "Filter by phone number (case-insensitive substring)" },
        address_city:           { type: "string", description: "Filter by city (case-insensitive substring)" },
        address_state:          { type: "string", description: "Filter by state (case-insensitive substring)" },
        address_zip_code:       { type: "string", description: "Filter by zip code (case-insensitive substring)" },
        social_security_number: { type: "string", description: "Filter by SSN (case-insensitive substring)" },
        passport_number:        { type: "string", description: "Filter by passport number (case-insensitive substring)" },
        drivers_license_number: { type: "string", description: "Filter by driver's license number (case-insensitive substring)" }
      },
    )
    annotations(read_only_hint: true, destructive_hint: false)

    def self.call(
      limit: 20, sort_by: "last_name", sort_direction: "asc",
      administrative_gender: nil,
      first_name: nil, last_name: nil, birth_date: nil, email: nil, phone_number: nil,
      address_city: nil, address_state: nil, address_zip_code: nil,
      social_security_number: nil, passport_number: nil, drivers_license_number: nil,
      server_context:
    )
      params = {
        limit:, sort_by:, sort_direction:, administrative_gender:,
        first_name:, last_name:, birth_date:, email:, phone_number:,
        address_city:, address_state:, address_zip_code:,
        social_security_number:, passport_number:, drivers_license_number:
      }
      log = AuditLog.create!(
        description: "LLM listed patient records",
        tags: {
          AuditLog::Tag::EVENT => AuditLog::Event::MCP_LIST_PATIENTS,
          AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP
        },
        encrypted_request: params
      )

      sort_col = SORTABLE_FIELDS.include?(sort_by.to_s) ? sort_by.to_s : "last_name"
      sort_dir = sort_direction.to_s == "desc" ? "desc" : "asc"
      max = [ (limit || 20).to_i, 1 ].max

      scope = PatientRecord.all
      TEXT_FILTER_FIELDS.each do |field|
        val = params[field.to_sym]
        scope = scope.where("LOWER(#{field}) LIKE ?", "%#{val.to_s.downcase}%") if val.present?
      end
      scope = scope.where(administrative_gender:) if administrative_gender.present?
      scope = scope.order(sort_col => sort_dir).limit(max)

      records = scope.to_a
      result_text = if records.empty?
        "No patient records found."
      else
        header = "Found #{records.size} patient record(s):\n\n"
        header + records.map(&:to_text).join("\n---\n\n")
      end

      log.update!(encrypted_response: result_text)
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end
  end
end
