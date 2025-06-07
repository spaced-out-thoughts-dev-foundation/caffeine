require_relative "../spec_helper"

RSpec.describe Agtron::Constraint do
  let(:origin) { Agtron::Component.new("origin", 100) }
  let(:dependent) { Agtron::Component.new("dependent", 95) }

  describe "#initialize" do
    context "with valid parameters" do
      it "creates a hard constraint" do
        constraint = described_class.new("hard", origin, dependent)
        expect(constraint).to be_a(described_class)
        expect(constraint.type).to eq("hard")
        expect(constraint.origin).to eq(origin)
        expect(constraint.dependent).to eq(dependent)
      end

      it "creates a soft constraint" do
        constraint = described_class.new("soft", origin, dependent)
        expect(constraint).to be_a(described_class)
        expect(constraint.type).to eq("soft")
      end

      it "works with string names as components" do
        constraint = described_class.new("hard", "service_a", "service_b")
        expect(constraint).to be_a(described_class)
        expect(constraint.origin).to eq("service_a")
        expect(constraint.dependent).to eq("service_b")
      end
    end

    context "with invalid constraint type" do
      it "raises error for invalid constraint type" do
        expect {
          described_class.new("invalid", origin, dependent)
        }.to raise_error("Invalid constraint type: invalid")
      end
    end

    context "with nil parameters" do
      it "raises error for nil origin" do
        expect {
          described_class.new("hard", nil, dependent)
        }.to raise_error("Origin and dependent must be non-nil")
      end

      it "raises error for nil dependent" do
        expect {
          described_class.new("hard", origin, nil)
        }.to raise_error("Origin and dependent must be non-nil")
      end
    end

    context "with self-referencing constraint" do
      it "raises error for self-loop" do
        expect {
          described_class.new("hard", origin, origin)
        }.to raise_error("Origin and dependent must be different")
      end
    end
  end

  describe "constants" do
    it "defines CONSTRAINT_HARD" do
      expect(Agtron::Constraint::CONSTRAINT_HARD).to eq("hard")
    end

    it "defines CONSTRAINT_SOFT" do
      expect(Agtron::Constraint::CONSTRAINT_SOFT).to eq("soft")
    end

    it "defines CONSTRAINT_TYPES" do
      expect(Agtron::Constraint::CONSTRAINT_TYPES).to eq(["hard", "soft"])
    end
  end

  describe "attribute readers" do
    let(:constraint) { described_class.new("hard", origin, dependent) }

    it "has type reader" do
      expect(constraint.type).to eq("hard")
    end

    it "has origin reader" do
      expect(constraint.origin).to eq(origin)
    end

    it "has dependent reader" do
      expect(constraint.dependent).to eq(dependent)
    end
  end
end
