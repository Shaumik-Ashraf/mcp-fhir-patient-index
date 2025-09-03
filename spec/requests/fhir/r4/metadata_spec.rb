require 'rails_helper'

RSpec.describe "/fhir/r4/metadata", type: :request do
  it "returns 200 ok" do
    get fhir_r4_metadata_url
    expect(response).to be_successful
  end

  it "returns a CapabilityStatement" do
    get fhir_r4_metadata_url
    expect(FHIR.from_contents(response.body)).to be_instance_of FHIR::CapabilityStatement
  end
end
