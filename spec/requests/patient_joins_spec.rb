require 'rails_helper'

RSpec.describe "/patient_joins", type: :request do
  let(:patient_1) { create(:patient) }
  let(:patient_2) { create(:patient) }

  let(:valid_attributes) {
    {
      from_patient_record_id: patient_1.id,
      to_patient_record_id: patient_2.id,
      qualifier: :has_same_identity_as,
      notes: "Test link"
    }
  }

  let(:invalid_attributes) {
    {
      from_patient_record_id: patient_1.id,
      to_patient_record_id: patient_1.id,  # Same patient - invalid
      qualifier: :has_same_identity_as
    }
  }

  describe "GET /new" do
    it "renders a successful response" do
      get new_patient_join_url
      expect(response).to be_successful
    end
  end

  describe "GET /compare" do
    context "with valid patient UUIDs" do
      it "renders a successful response" do
        get compare_patient_joins_url, params: {
          patient_1_uuid: patient_1.uuid,
          patient_2_uuid: patient_2.uuid
        }
        expect(response).to be_successful
      end

      it "displays both patient records" do
        get compare_patient_joins_url, params: {
          patient_1_uuid: patient_1.uuid,
          patient_2_uuid: patient_2.uuid
        }
        expect(response.body).to include(patient_1.uuid)
        expect(response.body).to include(patient_2.uuid)
      end

      it "shows the comparison form" do
        get compare_patient_joins_url, params: {
          patient_1_uuid: patient_1.uuid,
          patient_2_uuid: patient_2.uuid
        }
        expect(response.body).to include("Compare Patient Records")
        expect(response.body).to include("Link These Patient Records")
      end
    end

    context "with missing patient UUIDs" do
      it "redirects when first patient is missing" do
        get compare_patient_joins_url, params: {
          patient_2_uuid: patient_2.uuid
        }
        expect(response).to redirect_to(new_patient_join_path)
        expect(flash[:alert]).to match(/select two valid patient records/i)
      end

      it "redirects when second patient is missing" do
        get compare_patient_joins_url, params: {
          patient_1_uuid: patient_1.uuid
        }
        expect(response).to redirect_to(new_patient_join_path)
        expect(flash[:alert]).to match(/select two valid patient records/i)
      end
    end

    context "when trying to link a patient to itself" do
      it "redirects with an error" do
        get compare_patient_joins_url, params: {
          patient_1_uuid: patient_1.uuid,
          patient_2_uuid: patient_1.uuid
        }
        expect(response).to redirect_to(new_patient_join_path)
        expect(flash[:alert]).to match(/cannot link a patient record to itself/i)
      end
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new PatientJoin" do
        expect {
          post patient_joins_url, params: { patient_join: valid_attributes }
        }.to change(PatientJoin, :count).by(1)
      end

      it "redirects to the from patient record" do
        post patient_joins_url, params: { patient_join: valid_attributes }
        expect(response).to redirect_to(patient_record_url(patient_1))
      end

      it "sets a success notice" do
        post patient_joins_url, params: { patient_join: valid_attributes }
        expect(flash[:notice]).to match(/successfully linked/i)
      end
    end

    context "when trying to link a patient to itself" do
      it "does not create a new PatientJoin" do
        expect {
          post patient_joins_url, params: { patient_join: invalid_attributes }
        }.not_to change(PatientJoin, :count)
      end

      it "redirects with an error message" do
        post patient_joins_url, params: { patient_join: invalid_attributes }
        expect(response).to redirect_to(new_patient_join_path)
        expect(flash[:alert]).to match(/cannot link a patient record to itself/i)
      end
    end

    context "when a link already exists" do
      before do
        PatientJoin.create!(valid_attributes)
      end

      it "does not create a duplicate PatientJoin" do
        expect {
          post patient_joins_url, params: { patient_join: valid_attributes }
        }.not_to change(PatientJoin, :count)
      end

      it "redirects with a notice" do
        post patient_joins_url, params: { patient_join: valid_attributes }
        expect(response).to redirect_to(patient_record_url(patient_1))
        expect(flash[:notice]).to match(/already linked/i)
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:patient_join) { create(:patient_join, from: patient_1, to: patient_2) }

    it "destroys the requested patient_join" do
      expect {
        delete patient_join_url(patient_join)
      }.to change(PatientJoin, :count).by(-1)
    end

    it "redirects to the from patient record" do
      delete patient_join_url(patient_join)
      expect(response).to redirect_to(patient_record_url(patient_1))
    end

    it "sets a success notice" do
      delete patient_join_url(patient_join)
      expect(flash[:notice]).to match(/link removed/i)
    end
  end
end
