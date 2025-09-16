# frozen_string_literal: true

# MCP Resource that wraps PatientRecord, this is not
# directly related to the FHIR Patient resource but
# both are directly derived from PatientRecord
class PatientResource < ApplicationResource
  uri "patients/{uuid}" # TODO: use url helper or forge data helper?
  resource_name "Patients"
  description "Provide an LLM access to the Master Patient Index."
  mime_type "plain/text"

  def content
    patient = PatientRecord.find_by({ uuid: params[:uuid] })
    if patient
      patient.to_text
    else
      "Patient #{params[:uuid]} not found."
    end
  end
end
