require "rails_helper"

RSpec.describe PatientRecordsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/patients").to route_to("patient_records#index")
    end

    it "routes to #new" do
      expect(get: "/patients/new").to route_to("patient_records#new")
    end

    it "routes to #show" do
      expect(get: "/patients/1").to route_to("patient_records#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/patients/1/edit").to route_to("patient_records#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/patients").to route_to("patient_records#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/patients/1").to route_to("patient_records#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/patients/1").to route_to("patient_records#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/patients/1").to route_to("patient_records#destroy", id: "1")
    end
  end
end
