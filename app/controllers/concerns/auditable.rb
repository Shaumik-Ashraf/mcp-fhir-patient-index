# Concern that provides pre-built {AuditLog} callback methods for use in
# Rails controllers via +after_action+.
#
# @example Minimal usage in a controller
#   class MyController < ApplicationController
#     include Auditable
#
#     after_action :audit_patient_show, only: [:show]
#
#     private
#
#     def audit_interface
#       AuditLog::Interface::WEB
#     end
#   end
#
# @example Customizing request/response capture (e.g. for FHIR controllers)
#   class MyFhirController < ApplicationController
#     include Auditable
#
#     private
#
#     def audit_interface
#       AuditLog::Interface::FHIR
#     end
#
#     def audit_request_data
#       { body: request.body.string }
#     end
#
#     def audit_response_data
#       { status: response.status, body: response.body }
#     end
#   end
module Auditable
  extend ActiveSupport::Concern

  private

  # Creates an {AuditLog} record for the current request/response cycle.
  # Called internally by all audit callback methods.
  #
  # @param event [String] one of the {AuditLog::Event} constant values
  # @param description [String] human-readable summary of the audited action
  # @return [AuditLog] the persisted log record
  def audit(event:, description:)
    AuditLog.create!(
      description: description,
      tags: {
        AuditLog::Tag::EVENT => event,
        AuditLog::Tag::INTERFACE => audit_interface
      },
      encrypted_request: audit_request_data,
      encrypted_response: audit_response_data
    )
  end

  # @!group Required overrides

  # Returns the interface tag value for this controller.
  # Must be overridden in every including controller.
  #
  # @abstract
  # @return [String] one of the {AuditLog::Interface} constant values
  def audit_interface
    raise NotImplementedError, "#{self.class} must define #audit_interface"
  end

  # @!endgroup

  # @!group Optional overrides

  # Returns a serializable Hash representing the inbound request to be
  # stored encrypted in the audit log. Defaults to the full Rails params hash.
  # Override in controllers where request data is captured differently
  # (e.g. raw body for FHIR endpoints).
  #
  # @return [Hash]
  def audit_request_data
    request.params.to_h
  end

  # Returns a serializable Hash representing the outbound response to be
  # stored encrypted in the audit log. Defaults to HTTP status and redirect
  # location, suitable for Web UI controllers.
  # Override in controllers where richer response data should be captured
  # (e.g. rendered JSON body for FHIR endpoints).
  #
  # @return [Hash]
  def audit_response_data
    { status: response.status, location: response.location }
  end

  # @!endgroup

  # Web UI audit callbacks
  def audit_patient_index
    audit(event: AuditLog::Event::PATIENT_INDEX, description: "Patient index accessed")
  end

  def audit_patient_show
    audit(event: AuditLog::Event::PATIENT_READ, description: "Patient record read")
  end

  def audit_patient_create
    audit(event: AuditLog::Event::PATIENT_CREATE, description: "Patient record created")
  end

  def audit_patient_update
    audit(event: AuditLog::Event::PATIENT_UPDATE, description: "Patient record updated")
  end

  def audit_patient_destroy
    audit(event: AuditLog::Event::PATIENT_HARD_DELETE, description: "Patient record permanently destroyed")
  end

  def audit_auto_match
    audit(event: AuditLog::Event::PATIENT_AUTOMATCH, description: "Patient record auto-matching run")
  end

  def audit_unlink
    audit(event: AuditLog::Event::PATIENT_MANUAL_DELINK, description: "Patient record unlinked from all joins")
  end

  def audit_join_create
    audit(event: AuditLog::Event::PATIENT_MANUAL_LINK, description: "Patient records manually linked")
  end

  def audit_join_destroy
    audit(event: AuditLog::Event::PATIENT_MANUAL_DELINK, description: "Patient records manually unlinked")
  end

  # FHIR audit callbacks
  def audit_fhir_bundle
    audit(event: AuditLog::Event::FHIR_PATIENT_BUNDLE_FETCH, description: "FHIR patient bundle fetched")
  end

  def audit_fhir_patient_read
    audit(event: AuditLog::Event::FHIR_PATIENT_READ, description: "FHIR patient read")
  end

  def audit_fhir_match
    audit(event: AuditLog::Event::FHIR_DOLLAR_MATCH, description: "FHIR $match operation performed")
  end
end
