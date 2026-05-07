require 'rails_helper'

RSpec.describe Agent::FindPatientTool do
  let(:server_context) { {} }

  describe ".call" do
    context "when a matching patient exists" do
      let!(:patient) { create(:patient, last_name: "Uniqueson") }

      it "returns the patient's text representation" do
        response = described_class.call(last_name: "Uniqueson", server_context:)
        expect(response.content.first[:text]).to include("Uniqueson")
      end

      it "returns only one result even when multiple patients match" do
        create(:patient, last_name: "Uniqueson")
        response = described_class.call(last_name: "Uniqueson", server_context:)
        text = response.content.first[:text]
        expect(text).not_to include("---")
      end
    end

    context "when no patient matches" do
      it "returns a not-found message" do
        response = described_class.call(last_name: "Zzznomatch99999", server_context:)
        expect(response.content.first[:text]).to eq("No patient found matching the given criteria.")
      end
    end

    context "when no filters are provided" do
      it "returns an error message requiring at least one filter" do
        response = described_class.call(server_context:)
        expect(response.content.first[:text]).to include("At least one filter attribute is required")
      end
    end
  end
end
