module FHIR
  module R4
    class PatientsController < ApplicationController
      skip_forgery_protection
      # TODO: xml support

      # GET /fhir/r4/Patient/
      def index
        render json:
                 FHIR::Bundle.new(
                 {
                   type: "searchset",
                   total: PatientRecord.count,
                   entry: PatientRecord.all.map do |patient|
                     FHIR::Bundle::Entry.new(
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
        render json: PatientRecord.find_by_uuid!(params[:uuid]).to_fhir
      end

      # POST /fhir/r4/Patient/$match
      def match
        parameters = FHIR.from_contents(request.body.read)

        # FHIR operations spec allows sending Parameters or Patient directly
        if parameters.is_a?(FHIR::Parameters)
          resource = parameters.parameter.find { |p| p.name == "resource" }&.resource
          unless resource&.is_a?(FHIR::Patient)
            render json: fhir_operation_outcome("required", "Parameters.parameter.resource must be a Patient resource"),
                   status: :unprocessable_entity
            return
          end
          only_certain = parameters.parameter.find { |p| p.name == "onlyCertainMatches" }&.value == true
          count_param  = parameters.parameter.find { |p| p.name == "count" }&.value&.to_i
        elsif parameters.is_a?(FHIR::Patient)
          resource = parameters
        else
          render json: fhir_operation_outcome("invalid", "Expected a Parameters or Patient resource"),
                 status: :unprocessable_entity
          return
        end

        query     = PatientMatchInput.from_fhir(resource)
        threshold = Setting[:auto_match_threshold].to_f
        engine    = MatchingEngine.new

        scored = PatientRecord.all
                              .map { |r| [ r, engine.match_score(query, PatientMatchInput.from_patient_record(r)) ] }
                              .select { |_, score| score >= threshold }
                              .sort_by { |_, score| -score }

        scored = [ scored.first ].compact if only_certain
        scored = scored.first(count_param) if count_param

        entries = scored.map do |patient, score|
          FHIR::Bundle::Entry.new(
            {
              fullUrl: Rails.application.routes.url_helpers.fhir_r4_patient_url(patient),
              resource: patient.to_fhir,
              search: {
                mode: "match",
                extension: [
                  {
                    url: "http://hl7.org/fhir/StructureDefinition/match-grade",
                    valueCode: match_grade(score)
                  }
                ],
                score: score.round(4)
              }
            }
          )
        end

        render json: FHIR::Bundle.new({ type: "searchset", total: entries.size, entry: entries })
      end

      private

      def fhir_operation_outcome(code, message)
        FHIR::OperationOutcome.new(
          {
            issue: [
              {
                severity: "error",
                code: code,
                diagnostics: message
              }
            ]
          }
        )
      end

      def match_grade(score)
        score >= 0.9 ? "certain" : "possible"
      end
    end
  end
end
