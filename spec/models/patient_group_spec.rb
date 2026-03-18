require "rails_helper"

RSpec.describe PatientGroup, type: :model do
  describe ".index_by_patient_record_id" do
    it "returns an empty hash when no joins exist" do
      create(:patient)
      expect(PatientGroup.index_by_patient_record_id).to eq({})
    end

    it "assigns the same index to two directly linked records" do
      a = create(:patient)
      b = create(:patient)
      create(:patient_join, from: a, to: b)

      result = PatientGroup.index_by_patient_record_id
      expect(result[a.id]).to eq(result[b.id])
    end

    it "assigns the same index to transitively linked records" do
      a = create(:patient)
      b = create(:patient)
      c = create(:patient)
      create(:patient_join, from: a, to: b)
      create(:patient_join, from: b, to: c)

      result = PatientGroup.index_by_patient_record_id
      expect(result[a.id]).to eq(result[b.id])
      expect(result[b.id]).to eq(result[c.id])
    end

    it "assigns different indices to unconnected groups" do
      a = create(:patient)
      b = create(:patient)
      c = create(:patient)
      d = create(:patient)
      create(:patient_join, from: a, to: b)
      create(:patient_join, from: c, to: d)

      result = PatientGroup.index_by_patient_record_id
      expect(result[a.id]).not_to eq(result[c.id])
    end

    it "omits singleton records not in any join" do
      singleton = create(:patient)
      a = create(:patient)
      b = create(:patient)
      create(:patient_join, from: a, to: b)

      result = PatientGroup.index_by_patient_record_id
      expect(result.key?(singleton.id)).to be false
    end

    it "assigns index 1 to the component with the smallest min patient_record_id" do
      a = create(:patient)
      b = create(:patient)
      c = create(:patient)
      d = create(:patient)
      create(:patient_join, from: a, to: b)
      create(:patient_join, from: c, to: d)

      result = PatientGroup.index_by_patient_record_id
      expect(result[a.id]).to eq(1)
      expect(result[c.id]).to eq(2)
    end
  end
end
