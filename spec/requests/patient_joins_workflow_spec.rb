require 'rails_helper'

RSpec.describe "Patient Joins Workflow", type: :request do
  let(:patient_1) { create(:patient, first_name: "John", last_name: "Doe") }
  let(:patient_2) { create(:patient, first_name: "Jon", last_name: "Doe") }

  describe "complete linking workflow" do
    it "allows user to select, compare, and link two patient records" do
      # Step 1: Navigate to the selection page
      get new_patient_join_path
      expect(response).to be_successful
      expect(response.body).to include("Link Patient Records")

      # Step 2: Submit selection to compare page
      get compare_patient_joins_path, params: {
        patient_1_uuid: patient_1.uuid,
        patient_2_uuid: patient_2.uuid
      }
      expect(response).to be_successful
      expect(response.body).to include("Compare Patient Records")
      expect(response.body).to include(patient_1.first_name)
      expect(response.body).to include(patient_2.first_name)

      # Step 3: Submit the link
      expect {
        post patient_joins_path, params: {
          patient_join: {
            from_patient_record_id: patient_1.id,
            to_patient_record_id: patient_2.id,
            qualifier: :has_same_identity_as,
            notes: "Integration test link"
          }
        }
      }.to change(PatientJoin, :count).by(1)

      expect(response).to redirect_to(patient_record_path(patient_1))
      follow_redirect!
      expect(response.body).to include("successfully linked")

      # Verify the link was created correctly
      patient_join = PatientJoin.last
      expect(patient_join.from_patient_record).to eq(patient_1)
      expect(patient_join.to_patient_record).to eq(patient_2)
      expect(patient_join.notes).to eq("Integration test link")
    end

    it "allows user to unlink patient records" do
      # Create a link first
      patient_join = create(:patient_join, from: patient_1, to: patient_2)

      # Navigate to patient show page
      get patient_record_path(patient_1)
      expect(response).to be_successful
      expect(response.body).to include("Linked Patient Records")

      # Unlink the patients
      expect {
        delete patient_join_path(patient_join)
      }.to change(PatientJoin, :count).by(-1)

      expect(response).to redirect_to(patient_record_path(patient_1))
      follow_redirect!
      expect(response.body).to include("link removed")
    end
  end

  describe "error handling" do
    it "prevents linking a patient to itself" do
      # Try to compare a patient with itself
      get compare_patient_joins_path, params: {
        patient_1_uuid: patient_1.uuid,
        patient_2_uuid: patient_1.uuid
      }

      expect(response).to redirect_to(new_patient_join_path)
      follow_redirect!
      expect(response.body).to include("Cannot link a patient record to itself")
    end

    it "prevents creating duplicate links" do
      # Create a link first
      create(:patient_join, from: patient_1, to: patient_2)

      # Try to create the same link again
      expect {
        post patient_joins_path, params: {
          patient_join: {
            from_patient_record_id: patient_1.id,
            to_patient_record_id: patient_2.id,
            qualifier: :has_same_identity_as
          }
        }
      }.not_to change(PatientJoin, :count)

      expect(response).to redirect_to(patient_record_path(patient_1))
      follow_redirect!
      expect(response.body).to include("already linked")
    end

    it "handles missing patient UUIDs" do
      get compare_patient_joins_path, params: {
        patient_1_uuid: patient_1.uuid
        # patient_2_uuid is missing
      }

      expect(response).to redirect_to(new_patient_join_path)
      follow_redirect!
      expect(response.body).to include("select two valid patient records")
    end
  end

  describe "view integration" do
    it "shows link button on patient show page" do
      get patient_record_path(patient_1)
      expect(response).to be_successful
      expect(response.body).to include("Link to Another Patient")
      expect(response.body).to include(new_patient_join_path(patient_1_uuid: patient_1.uuid))
    end

    it "displays linked patients on patient show page" do
      create(:patient_join, from: patient_1, to: patient_2)

      get patient_record_path(patient_1)
      expect(response).to be_successful
      expect(response.body).to include("Linked Patient Records")
      expect(response.body).to include(patient_2.uuid)
      expect(response.body).to include("Unlink")
    end
  end
end
