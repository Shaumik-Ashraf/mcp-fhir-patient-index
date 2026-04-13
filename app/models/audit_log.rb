class AuditLog < ApplicationRecord
  encrypts :encrypted_request
  encrypts :encrypted_response
  validates :encrypted_request, presence: true
  validates :encrypted_response, presence: true
  validates :description, presence: true
  validate :tags_json_map

  # @private
  # Tags are hard-coded structured data
  class Tag
    EVENT = "event"
    INTERFACE = "interface"
  end

  # @private
  # All auditable events must be enumerated here
  class Event
    PATIENT_INDEX = "Index Patient Record"
    PATIENT_CREATE = "Create Patient Record"
    PATIENT_UPDATE = "Update Patient Record"
    PATIENT_READ = "Read Patient Record"
    PATIENT_SOFT_DELETE = "Soft Delete Patient Record"
    PATIENT_HARD_DELETE = "Permanently Destroy Patient Record"
    PATIENT_AUTOMATCH = "Run Patient Record Auto-Matching"
    PATIENT_MANUAL_LINK = "Manually Link Patient Records"
    PATIENT_MANUAL_DELINK = "Manually Unlink Patient Records"
    FHIR_PATIENT_BUNDLE_FETCH = "FHIR Read All Patients"
    FHIR_PATIENT_READ = "FHIR Read Patient"
    FHIR_DOLLAR_MATCH = "FHIR $match Operation"
    MCP_READ_ALL_PATIENTS = "LLM Read All Patients"
    MCP_CREATE_PATIENT = "LLM Create Patient Record"
    MCP_LINK_PATIENT = "LLM Link Patient Records"
    MCP_DELINK_PATIENT = "LLM Unlink Patient Records"
    UNKNOWN = "Unknown (See Description)"
  end

  # @private
  # All interface tag values are enumerated here
  class Interface
    FHIR = "FHIR"
    MCP = "MCP"
    WEB = "Web-UI"
  end

  private

  # @private
  # This validation function strictly checks the structure of the
  # serialized JSON object. This function and documentation MAY
  # need to be updated if updating the schema of `tags`. An example
  # `tags` object is:
  #
  # {
  #   "event": "Patient $match operation"
  #   "interface": "FHIR"
  # }
  def tags_json_map
    unless tags.is_a? Hash
      errors.add(:tags, "must be a JSON object")
      return
    end

    tags.keys.each do |k|
      unless Tag.constants.include? k.to_sym
        errors.add(:tags, "The tag #{k} must be defined in AuditLog::Tag")
      end
    end

    if tags.key? Tag::EVENT
      unless Event.constants.include? tags[Tag::EVENT]
        errors.add(:tags, "The #{Tag::EVENT} tag must be defined in AuditLog::Event")
      end
    end

    if tags.key? Tag::INTERFACE
      unless Interface.constants.include? tags[Tag::INTERFACE]
        errors.add(:tags, "The #{Tag::INTERFACE} tag must be defined in AuditLog::Interface")
      end
    end
  end
end
