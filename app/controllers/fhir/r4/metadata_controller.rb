module FHIR
  module R4
    class MetadataController < ApplicationController
      LAST_UPDATED = DateTime.new(2025, 10, 17) # TODO: autodetect fhir api chenges

      # TODO: XML support
      # GET /fhir/r4/metadata
      def index
        render json: FHIR::CapabilityStatement.new(
                 {
                   url: Rails.application.routes.url_helpers.fhir_r4_metadata_url,
                   version: Rails.application.config.x.version,
                   date: LAST_UPDATED.strftime("%Y-%m-%d"), # TODO: dry fhir date?
                   kind: "instance",
                   fhirVersion: "4.0.1",
                   format: [ "json" ],
                   rest: [
                     {
                       mode: "server",
                       documentation: File.read(Rails.root.join("README.md")),
                       resource: [
                         FHIR::BackboneElement.new(
                           {
                             type: "Patient",
                             interaction: [
                               FHIR::BackboneElement.new({ code: "read" })
                             ]
                           }
                         )
                       ]
                     }
                   ]
                 }
               )
      end
    end
  end
end
