module FHIR
  module R4
    class PatientsController < ApplicationController
      # TODO: xml support

      # GET /fhir/r4/Patient/
      def index
        render json:
                 FHIR::Bundle.new(
                 {
                   type: "searchset",
                   total: ::PatientRecord.count,
                   entry: ::PatientRecord.all.map do |patient|
                     FHIR::BackboneElement.new(
                       {
                         fullUrl: Rails.application.routes.url_helpers.fhir_r4_patient_url(patient),
                         resource: patient.to_fhir
                       }
                     )
                   end
                 }
               )
      end

      # GET /fhir/r4/Patient/123
      def show
        render json: ::PatientRecord.find_by_uuid!(params[:uuid]).to_fhir
      end
    end
  end
end
