require 'rails_helper'

RSpec.describe "/fhir/r4/Patient", type: :request do
  context "without search parameters" do
    it "returns 200 ok" do
      get fhir_r4_patients_url
      expect(response).to be_successful
    end

    it "returns a Bundle" do
      get fhir_r4_patients_url
      expect(FHIR.from_contents(response.body)).to be_instance_of FHIR::Bundle
    end
  end
end
