require "rails_helper"

RSpec.describe FHIR::R4::MetadataController, type: :routing do
  describe "routing" do
    it "routes /metadata to #index" do
      expect(get: "/fhir/r4/metadata").to route_to("fhir/r4/metadata#index")
    end
  end
end
