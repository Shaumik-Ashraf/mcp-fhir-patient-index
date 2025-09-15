require 'rails_helper'

RSpec.describe PatientRecord, type: :model do
  let(:patient) { create(:patient) }

  it "can instantiate random patient" do
    expect(patient).to be_instance_of described_class
  end

  it "can return clinical attributes" do
    expect(patient.clinical_attributes).not_to be_empty
  end

  it "can override url ID with UUID" do
    expect(patient.to_param).to be patient.uuid
  end

  describe "#name?" do
    it "returns true if last name only" do
      patient_with_name = create(:patient, last_name: "A")
      patient_with_name.first_name = nil
      expect(patient_with_name.name?).to be true
    end

    it "returns false if no first name nor last name" do
      patient_without_name = create(:patient)
      patient_without_name.first_name = nil
      patient_without_name.last_name = nil

      expect(patient_without_name.name?).to be false
    end
  end

  describe "#age" do
    it "can compute patient's age" do
      two_yo = create(:patient, birth_date: 2.years.ago)
      expect(two_yo.age).to be 2
    end

    it "can compute patient's age before birthday" do
      forty_yo = create(:patient, birth_date: 41.years.ago + 5.days)
      expect(forty_yo.age).to be 40
    end
  end

  describe "#address?" do
    it "returns true for zipcode only" do
      patient_with_address = create(:patient,
                                    address_line1: nil,
                                    address_line2: nil,
                                    address_city: nil,
                                    address_state: nil,
                                    address_zip_code: "11111")
      expect(patient_with_address.address?).to be true
    end

    it "returns false for no address elements" do
      patient_without_address = create(:patient,
                                       address_line1: nil,
                                       address_line2: nil,
                                       address_city: nil,
                                       address_state: nil,
                                       address_zip_code: nil)
      expect(patient_without_address.address?).to be false
    end
  end

  # Further FHIR validation will be done by Inferno
  describe "#to_fhir" do
    it "can convert to FHIR" do
      expect(patient.to_fhir).to be_instance_of FHIR::Patient
    end

    it "can convert to FHIR JSON" do
      expect { JSON.parse(patient.to_fhir.to_json) }.not_to raise_error
    end

    it "can convert to FHIR XML" do
      expect { Nokogiri::XML(patient.to_fhir.to_xml) }.not_to raise_error
    end
  end

  describe "#to_text" do
    it "returns String" do
      expect(patient.to_text).to be_instance_of String
    end
  end
end
