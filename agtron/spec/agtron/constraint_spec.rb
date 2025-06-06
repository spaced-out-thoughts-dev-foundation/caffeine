require_relative "../spec_helper"

RSpec.describe Agtron::Constraint do
  let(:origin) { Agtron::Component.new("origin") }
  let(:dependent) { Agtron::Component.new("dependent") }

  describe "#initialize" do
    it "creates a hard constraint" do
      constraint = described_class.new("test", "hard", origin, dependent)
      expect(constraint).to be_a(described_class)
    end

    it "raises error for invalid constraint type" do
      expect {
        described_class.new("test", "invalid", origin, dependent)
      }.to raise_error("Invalid constraint type: invalid")
    end
  end
end
