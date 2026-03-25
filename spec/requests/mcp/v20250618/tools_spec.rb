require 'rails_helper'

RSpec.describe "MCP Tools", type: :request do
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  def jsonrpc(method, params = {}, id: 1)
    { jsonrpc: "2.0", id: id, method: method, params: params }.to_json
  end

  describe "tools/list" do
    it "returns both tool names" do
      post mcp_v20250618_url, params: jsonrpc("tools/list"), headers: headers
      tools = JSON.parse(response.body).dig("result", "tools")
      names = tools.map { |t| t["name"] }
      expect(names).to include("create_patient", "link_patients")
    end
  end

  describe "tools/call — create_patient" do
    let(:payload) do
      jsonrpc("tools/call", {
        name: "create_patient",
        arguments: { first_name: "Jane", last_name: "Doe" }
      })
    end

    it "returns 200" do
      post mcp_v20250618_url, params: payload, headers: headers
      expect(response).to be_successful
    end

    it "returns isError false" do
      post mcp_v20250618_url, params: payload, headers: headers
      expect(JSON.parse(response.body).dig("result", "isError")).to be_falsey
    end

    it "creates the patient record in the database" do
      expect {
        post mcp_v20250618_url, params: payload, headers: headers
      }.to change { PatientRecord.where(first_name: "Jane", last_name: "Doe").count }.by(1)
    end
  end

  describe "tools/call — link_patients" do
    let!(:patient1) { create(:patient) }
    let!(:patient2) { create(:patient) }

    let(:payload) do
      jsonrpc("tools/call", {
        name: "link_patients",
        arguments: { patient_uuid_1: patient1.uuid, patient_uuid_2: patient2.uuid }
      })
    end

    it "returns 200" do
      post mcp_v20250618_url, params: payload, headers: headers
      expect(response).to be_successful
    end

    it "returns isError false" do
      post mcp_v20250618_url, params: payload, headers: headers
      expect(JSON.parse(response.body).dig("result", "isError")).to be_falsey
    end

    it "creates a PatientJoin between the two records" do
      expect {
        post mcp_v20250618_url, params: payload, headers: headers
      }.to change { PatientJoin.where(from_patient_record: patient1, to_patient_record: patient2).count }.by(1)
    end
  end
end
