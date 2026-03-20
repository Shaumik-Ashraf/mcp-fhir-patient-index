require "rails_helper"

RSpec.describe "POST /fhir/r4/Patient/$match", type: :request do
  def build_match_parameters(patient_record, only_certain: nil, count: nil)
    params = [
      { "name" => "resource", "resource" => patient_record.to_fhir.to_hash }
    ]
    params << { "name" => "onlyCertainMatches", "valueBoolean" => only_certain } unless only_certain.nil?
    params << { "name" => "count", "valueInteger" => count } unless count.nil?
    { "resourceType" => "Parameters", "parameter" => params }.to_json
  end

  before(:all) do
    Setting.find_or_create_by(key: "auto_match_threshold") do |s|
      s.value = 0.7
    end
  end

  let!(:alice) do
    create(:patient,
      first_name: "Alice",
      last_name: "Smith",
      birth_date: Date.new(1985, 4, 12),
      social_security_number: "111-22-3333"
    )
  end

  let!(:bob) do
    create(:patient,
      first_name: "Bob",
      last_name: "Jones",
      birth_date: Date.new(1970, 7, 4),
      social_security_number: "999-88-7777"
    )
  end

  context "with a matching patient" do
    before do
      post fhir_r4_patient_match_url,
           params: build_match_parameters(alice),
           headers: { "Content-Type" => "application/json" }
    end

    it "returns 200 ok" do
      expect(response).to be_successful
    end

    it "returns a Bundle searchset" do
      bundle = FHIR.from_contents(response.body)
      expect(bundle).to be_instance_of FHIR::Bundle
      expect(bundle.type).to eq "searchset"
    end

    it "includes alice in the results" do
      bundle = FHIR.from_contents(response.body)
      uuids = bundle.entry.map { |e| e.resource.id }
      expect(uuids).to include alice.uuid
    end

    it "entries have search.score between 0 and 1" do
      bundle = FHIR.from_contents(response.body)
      scores = bundle.entry.map { |e| e.search.score }
      expect(scores).to all(be_between(0.0, 1.0))
    end

    it "entries have a match-grade extension" do
      bundle = FHIR.from_contents(response.body)
      bundle.entry.each do |entry|
        grades = entry.search.extension.select { |ext|
          ext.url == "http://hl7.org/fhir/StructureDefinition/match-grade"
        }
        expect(grades).not_to be_empty
        expect(grades.first.valueCode).to be_in(%w[certain possible])
      end
    end

    it "results are sorted by score descending" do
      bundle = FHIR.from_contents(response.body)
      scores = bundle.entry.map { |e| e.search.score }
      expect(scores).to eq scores.sort.reverse
    end
  end

  context "with onlyCertainMatches=true" do
    before do
      post fhir_r4_patient_match_url,
           params: build_match_parameters(alice, only_certain: true),
           headers: { "Content-Type" => "application/json" }
    end

    it "returns at most one entry" do
      bundle = FHIR.from_contents(response.body)
      expect(bundle.entry.size).to be <= 1
    end
  end

  context "with count=1" do
    before do
      create(:patient, social_security_number: alice.social_security_number, birth_date: alice.birth_date)
      post fhir_r4_patient_match_url,
           params: build_match_parameters(alice, count: 1),
           headers: { "Content-Type" => "application/json" }
    end

    it "returns at most one entry" do
      bundle = FHIR.from_contents(response.body)
      expect(bundle.entry.size).to be <= 1
    end
  end

  context "with an invalid body" do
    before do
      post fhir_r4_patient_match_url,
           params: { "resourceType" => "Patient" }.to_json,
           headers: { "Content-Type" => "application/json" }
    end

    it "returns 422" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns an OperationOutcome" do
      expect(FHIR.from_contents(response.body)).to be_instance_of FHIR::OperationOutcome
    end
  end

  context "with a Parameters body missing the resource parameter" do
    before do
      post fhir_r4_patient_match_url,
           params: { "resourceType" => "Parameters", "parameter" => [] }.to_json,
           headers: { "Content-Type" => "application/json" }
    end

    it "returns 422" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns an OperationOutcome" do
      expect(FHIR.from_contents(response.body)).to be_instance_of FHIR::OperationOutcome
    end
  end
end
