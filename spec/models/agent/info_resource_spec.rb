require 'rails_helper'

RSpec.describe Agent::InfoResource do
  describe ".resource" do
    it "returns an MCP::Resource with the correct metadata" do
      resource = described_class.resource

      expect(resource).to be_a(MCP::Resource)
      expect(resource.uri).to eq("mpi://info")
      expect(resource.name).to eq("info")
      expect(resource.title).to eq("MCP Server Info")
      expect(resource.description).to eq("Information about this Master Patient Index MCP server")
      expect(resource.mime_type).to eq("text/plain")
    end
  end

  describe ".read" do
    it "returns the server info text" do
      text = described_class.read

      expect(text).to include("master patient index server")
      expect(text).to include("model context")
      expect(text).to include("protocol (MCP)")
      expect(text).to include("patient records")
    end
  end
end