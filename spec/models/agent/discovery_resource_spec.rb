require 'rails_helper'

RSpec.describe Agent::DiscoveryResource do
  describe ".resource" do
    it "returns an MCP::Resource with the correct metadata" do
      resource = described_class.resource

      expect(resource).to be_a(MCP::Resource)
      expect(resource.uri).to eq("mpi://discovery")
      expect(resource.name).to eq("discovery")
      expect(resource.title).to eq("MCP Discovery")
      expect(resource.description).to include("survey of all available MCP")
      expect(resource.mime_type).to eq("text/plain")
    end
  end

  describe ".read" do
    it "includes a survey of tools" do
      text = described_class.read

      expect(text).to include("## Tools")
      expect(text).to include("read_patient")
    end

    it "includes a prompts section" do
      text = described_class.read

      expect(text).to include("## Prompts")
    end

    it "includes a survey of resources" do
      text = described_class.read

      expect(text).to include("## Resources")
      expect(text).to include("mpi://info")
      expect(text).to include("mpi://discovery")
    end

    it "includes a survey of resource templates" do
      text = described_class.read

      expect(text).to include("## Resource Templates")
      expect(text).to include("patient_record")
      expect(text).to include("mpi://patient_record/{id}")
    end
  end
end