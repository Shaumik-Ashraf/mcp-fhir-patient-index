require "rails_helper"

# Tests the Auditable concern via anonymous controllers as shown in
# the documented @example blocks on the concern itself.
RSpec.describe Auditable, type: :controller do
  context "minimal usage — include Auditable and define #audit_interface" do
    controller(ApplicationController) do
      include Auditable

      after_action :audit_patient_show, only: [ :show ]

      def show
        render plain: "ok"
      end

      private

      def audit_interface
        AuditLog::Interface::WEB
      end
    end

    before { routes.draw { get "show" => "anonymous#show" } }

    it "creates an AuditLog entry on action" do
      expect { get :show }.to change(AuditLog, :count).by(1)
    end

    it "tags the entry with the correct event and interface" do
      get :show
      log = AuditLog.last
      expect(log.tags[AuditLog::Tag::EVENT]).to eq(AuditLog::Event::PATIENT_READ)
      expect(log.tags[AuditLog::Tag::INTERFACE]).to eq(AuditLog::Interface::WEB)
    end

    it "captures request params as encrypted_request" do
      get :show
      expect(AuditLog.last.encrypted_request).to be_a(Hash)
    end

    it "captures response status as encrypted_response" do
      get :show
      expect(AuditLog.last.encrypted_response).to include("status" => 200)
    end
  end

  context "customized capture — override #audit_request_data and #audit_response_data" do
    controller(ApplicationController) do
      include Auditable

      after_action :audit_fhir_bundle, only: [ :index ]

      def index
        render plain: "bundle"
      end

      private

      def audit_interface
        AuditLog::Interface::FHIR
      end

      def audit_request_data
        { body: request.body&.string }
      end

      def audit_response_data
        { status: response.status, body: response.body }
      end
    end

    before { routes.draw { get "index" => "anonymous#index" } }

    it "creates an AuditLog entry on action" do
      expect { get :index }.to change(AuditLog, :count).by(1)
    end

    it "tags the entry with the FHIR interface" do
      get :index
      expect(AuditLog.last.tags[AuditLog::Tag::INTERFACE]).to eq(AuditLog::Interface::FHIR)
    end

    it "captures the custom request data" do
      get :index
      expect(AuditLog.last.encrypted_request).to have_key("body")
    end

    it "captures the response body in encrypted_response" do
      get :index
      expect(AuditLog.last.encrypted_response).to include("body" => "bundle")
    end
  end

  context "missing #audit_interface" do
    controller(ApplicationController) do
      include Auditable

      after_action :audit_patient_show, only: [ :show ]

      def show
        render plain: "ok"
      end
    end

    before { routes.draw { get "show" => "anonymous#show" } }

    it "raises NotImplementedError" do
      expect { get :show }.to raise_error(NotImplementedError)
    end
  end
end
