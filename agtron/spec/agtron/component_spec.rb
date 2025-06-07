require_relative "../spec_helper"

RSpec.describe Agtron::Component do
  describe "#initialize" do
    context "with valid parameters" do
      it "creates a component with integer availability" do
        component = described_class.new("service_a", 100)
        expect(component).to be_a(described_class)
        expect(component.name).to eq("service_a")
        expect(component.availability).to eq(100)
      end

      it "creates a component with float availability" do
        component = described_class.new("service_b", 95.5)
        expect(component).to be_a(described_class)
        expect(component.name).to eq("service_b")
        expect(component.availability).to eq(95.5)
      end

      it "creates a component with zero availability" do
        component = described_class.new("service_c", 0)
        expect(component).to be_a(described_class)
        expect(component.availability).to eq(0)
      end

      it "creates a component with negative availability" do
        component = described_class.new("service_d", -10)
        expect(component).to be_a(described_class)
        expect(component.availability).to eq(-10)
      end

      it "creates a component with unknown availability" do
        component = described_class.new("service_e", "unknown")
        expect(component).to be_a(described_class)
        expect(component.name).to eq("service_e")
        expect(component.availability).to eq("unknown")
      end
    end

    context "with invalid availability" do
      it "raises error for string availability (other than 'unknown')" do
        expect {
          described_class.new("service_a", "available")
        }.to raise_error("Availability must be a number or 'unknown'")
      end

      it "raises error for nil availability" do
        expect {
          described_class.new("service_a", nil)
        }.to raise_error("Availability must be a number or 'unknown'")
      end

      it "raises error for boolean availability" do
        expect {
          described_class.new("service_a", true)
        }.to raise_error("Availability must be a number or 'unknown'")
      end

      it "raises error for array availability" do
        expect {
          described_class.new("service_a", [1, 2, 3])
        }.to raise_error("Availability must be a number or 'unknown'")
      end

      it "raises error for hash availability" do
        expect {
          described_class.new("service_a", {availability: 100})
        }.to raise_error("Availability must be a number or 'unknown'")
      end

      it "raises error for symbol availability (other than string 'unknown')" do
        expect {
          described_class.new("service_a", :unknown)
        }.to raise_error("Availability must be a number or 'unknown'")
      end

      it "raises error for uppercase 'UNKNOWN'" do
        expect {
          described_class.new("service_a", "UNKNOWN")
        }.to raise_error("Availability must be a number or 'unknown'")
      end
    end
  end

  describe "attribute readers" do
    let(:component) { described_class.new("test_service", 80) }

    it "has name reader" do
      expect(component.name).to eq("test_service")
    end

    it "has availability reader" do
      expect(component.availability).to eq(80)
    end

    context "with unknown availability" do
      let(:unknown_component) { described_class.new("unknown_service", "unknown") }

      it "returns 'unknown' for availability" do
        expect(unknown_component.availability).to eq("unknown")
      end
    end
  end
end
