require "rails_helper"

RSpec.describe "/audit_logs", type: :request do
  let!(:audit_log) { create(:audit_log) }

  describe "GET /audit_logs" do
    it "returns http success" do
      get audit_logs_path
      expect(response).to have_http_status(:success)
    end

    it "filters by interface" do
      get audit_logs_path, params: { interface: AuditLog::Interface::WEB }
      expect(response).to have_http_status(:success)
    end

    it "filters by event" do
      get audit_logs_path, params: { event: AuditLog::Event::PATIENT_READ }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /audit_logs/:id" do
    it "returns http success" do
      get audit_log_path(audit_log)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /audit_logs/:id/download_request" do
    it "returns a JSON file download" do
      get download_request_audit_log_path(audit_log)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")
    end
  end

  describe "GET /audit_logs/:id/download_response" do
    it "returns a JSON file download" do
      get download_response_audit_log_path(audit_log)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")
    end
  end
end
