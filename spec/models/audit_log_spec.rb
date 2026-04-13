require "rails_helper"

RSpec.describe AuditLog, type: :model do
  let(:audit_log) { create(:audit_log) }

  it "can be created from factory" do
    expect(audit_log).to be_instance_of described_class
  end

  describe "validations" do
    it "is valid with all required fields" do
      expect(audit_log).to be_valid
    end

    it "requires description" do
      audit_log.description = nil
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:description]).to be_present
    end

    it "requires encrypted_request" do
      audit_log.encrypted_request = nil
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:encrypted_request]).to be_present
    end

    it "requires encrypted_response" do
      audit_log.encrypted_response = nil
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:encrypted_response]).to be_present
    end
  end

  describe "tags validation" do
    it "is valid with empty tags hash" do
      audit_log.tags = {}
      expect(audit_log).to be_valid
    end

    it "is valid with only event tag" do
      audit_log.tags = { AuditLog::Tag::EVENT => AuditLog::Event::PATIENT_CREATE }
      expect(audit_log).to be_valid
    end

    it "is valid with only interface tag" do
      audit_log.tags = { AuditLog::Tag::INTERFACE => AuditLog::Interface::FHIR }
      expect(audit_log).to be_valid
    end

    it "is invalid when tags is not a Hash" do
      audit_log.tags = "invalid"
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:tags]).to include("must be a JSON object")
    end

    it "is invalid with unknown tag key" do
      audit_log.tags = { "foo" => "bar" }
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:tags]).to be_present
    end

    it "is invalid with unknown event value" do
      audit_log.tags = { AuditLog::Tag::EVENT => "Not A Real Event" }
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:tags]).to be_present
    end

    it "is valid with any known event value" do
      AuditLog::Event.constants.each do |const|
        audit_log.tags = { AuditLog::Tag::EVENT => AuditLog::Event.const_get(const) }
        expect(audit_log).to be_valid, "Expected #{const} to be a valid event"
      end
    end

    it "is invalid with unknown interface value" do
      audit_log.tags = { AuditLog::Tag::INTERFACE => "Unknown Interface" }
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:tags]).to be_present
    end

    it "is valid with any known interface value" do
      AuditLog::Interface.constants.each do |const|
        audit_log.tags = { AuditLog::Tag::INTERFACE => AuditLog::Interface.const_get(const) }
        expect(audit_log).to be_valid, "Expected #{const} to be a valid interface"
      end
    end
  end

  describe "AuditLog::Tag" do
    it "defines EVENT as 'event'" do
      expect(AuditLog::Tag::EVENT).to eq("event")
    end

    it "defines INTERFACE as 'interface'" do
      expect(AuditLog::Tag::INTERFACE).to eq("interface")
    end
  end

  describe "AuditLog::Interface" do
    it "defines FHIR" do
      expect(AuditLog::Interface::FHIR).to eq("FHIR")
    end

    it "defines MCP" do
      expect(AuditLog::Interface::MCP).to eq("MCP")
    end

    it "defines WEB" do
      expect(AuditLog::Interface::WEB).to eq("Web-UI")
    end
  end

end
