module FHIR
  module R4
    class MetadataController < ApplicationController
      LAST_UPDATED = DateTime.new(2025,9,2) # TODO: autodetect fhir api chenges

      # GET /fhir/r4/metadata
      def index
        render json: FHIR::CapabilityStatement.new(
                 {
                   date: LAST_UPDATED,
                   kind: 'instance',
                   fhirVersion: '4.0.1',
                   format: [ 'json' ],
                   rest: [{
                            mode: 'server',
                            documentation: File.read(Rails.root.join("README.md"))
                            # TODO: resource
                          }]
                 })
      end
    end
  end
end
