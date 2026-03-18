require 'rails_helper'

RSpec.describe MatchingEngine do
  subject(:engine) { described_class.new }

  let(:base) do
    build(
      :patient,
      first_name: "Link",
      last_name: "Base",
      birth_date: Date.new(1939, 2, 2),
      social_security_number: "999-99-9999"
    )
  end

  let(:identical) { base.dup }

  let(:different) do
    build(:patient,
      first_name: "Zelda",
      last_name: "Xylophone",
      birth_date: Date.new(1940, 1, 1),
      social_security_number: "000-00-0000"
    )
  end

  describe "#match_score" do
    it "returns 1.0 for identical records" do
      expect(engine.match_score(base, identical)).to eq(1.0)
    end

    it "returns less than 0.5 for completely different records" do
      expect(engine.match_score(base, different)).to be < 0.5
    end
  end

  describe "#match?" do
    it "returns true when match_score meets the threshold" do
      expect(engine.match?(base, identical, threshold: 0.5)).to be true
    end

    it "returns false when match_score is below the threshold" do
      expect(engine.match?(base, different, threshold: 0.5)).to be false
    end
  end
end
