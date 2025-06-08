require_relative "../spec_helper"

RSpec.describe Agtron::Parser do
  describe ".parse_yaml" do
    context "with valid YAML format" do
      it "parses simple service without dependencies" do
        yaml_content = <<~YAML
          - service: "service_a"
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(1)
        expect(system.constraints.length).to eq(0)
        expect(system.component_exists?("service_a")).to be(true)
        expect(system.component_by_name("service_a").availability).to eq("unknown")
      end

      it "parses service with single dependency" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: ["service_b"]
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(1)
        expect(system.constraints.length).to eq(1)
        expect(system.component_exists?("service_a")).to be(true)
        expect(system.direct_constraint_exists?("service_a", "service_b")).to be(true)
      end

      it "parses service with multiple dependencies" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: ["service_b", "service_c"]
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(1)
        expect(system.constraints.length).to eq(2)
        expect(system.direct_constraint_exists?("service_a", "service_b")).to be(true)
        expect(system.direct_constraint_exists?("service_a", "service_c")).to be(true)
      end

      it "parses multiple services with dependencies" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: ["service_b"]
          - service: "service_b"
            depends_on: ["service_c", "service_d"]
          - service: "service_c"
          - service: "service_d"
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(4)
        expect(system.constraints.length).to eq(3)

        # Verify all components exist
        expect(system.component_exists?("service_a")).to be(true)
        expect(system.component_exists?("service_b")).to be(true)
        expect(system.component_exists?("service_c")).to be(true)
        expect(system.component_exists?("service_d")).to be(true)

        # Verify constraints
        expect(system.direct_constraint_exists?("service_a", "service_b")).to be(true)
        expect(system.direct_constraint_exists?("service_b", "service_c")).to be(true)
        expect(system.direct_constraint_exists?("service_b", "service_d")).to be(true)

        # Verify all components have unknown availability
        expect(system.component_by_name("service_a").availability).to eq("unknown")
        expect(system.component_by_name("service_b").availability).to eq("unknown")
        expect(system.component_by_name("service_c").availability).to eq("unknown")
        expect(system.component_by_name("service_d").availability).to eq("unknown")
      end

      it "parses example from user specification" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: ["service_b"]
          - service: "service_b"
            depends_on: ["service_c", "service_d"]
          - service: "service_c"
          - service: "service_d"
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.valid?).to be(true)

        # Verify the dependency chain
        expect(system.indirect_constraint_exists?("service_a", "service_c")).to be(true)
        expect(system.indirect_constraint_exists?("service_a", "service_d")).to be(true)

        # Verify constraint paths
        expect(system.constraint_path("service_a", "service_c")).to eq(["service_a", "service_b", "service_c"])
        expect(system.constraint_path("service_a", "service_d")).to eq(["service_a", "service_b", "service_d"])
      end

      it "handles services with no dependencies specified" do
        yaml_content = <<~YAML
          - service: "service_a"
          - service: "service_b"
            depends_on: ["service_a"]
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(2)
        expect(system.constraints.length).to eq(1)
        expect(system.direct_constraint_exists?("service_b", "service_a")).to be(true)
      end

      it "creates hard constraints by default" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: ["service_b"]
        YAML

        system = described_class.parse_yaml(yaml_content)
        constraint = system.direct_constraint_by_origin_and_dependent("service_a", "service_b")

        expect(constraint.type).to eq("hard")
      end

      it "handles empty dependencies array" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: []
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(1)
        expect(system.constraints.length).to eq(0)
      end
    end

    context "with availability attributes" do
      it "parses service with numeric availability" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: 99.5
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(1)
        expect(system.component_by_name("service_a").availability).to eq(99.5)
      end

      it "parses service with integer availability" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: 95
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.component_by_name("service_a").availability).to eq(95)
      end

      it "parses service with unknown availability explicitly" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: "unknown"
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.component_by_name("service_a").availability).to eq("unknown")
      end

      it "parses mixed availability values" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: 95.0
            depends_on: ["service_b", "service_c"]
          - service: "service_b"
            availability: "unknown"
          - service: "service_c"
            availability: 99.9
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(3)
        expect(system.component_by_name("service_a").availability).to eq(95.0)
        expect(system.component_by_name("service_b").availability).to eq("unknown")
        expect(system.component_by_name("service_c").availability).to eq(99.9)
      end

      it "defaults to unknown when availability is not specified" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: 95.0
          - service: "service_b"
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.component_by_name("service_a").availability).to eq(95.0)
        expect(system.component_by_name("service_b").availability).to eq("unknown")
      end

      it "validates availability values and raises errors for invalid ones" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: "invalid"
        YAML

        expect {
          described_class.parse_yaml(yaml_content)
        }.to raise_error("Availability must be a number or 'unknown'")
      end

      it "handles zero availability" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: 0
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.component_by_name("service_a").availability).to eq(0)
      end

      it "handles negative availability" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: -5.0
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.component_by_name("service_a").availability).to eq(-5.0)
      end

      it "creates valid system with proper availability constraints" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: 95.0
            depends_on: ["service_b"]
          - service: "service_b"
            availability: 99.0
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.valid?).to be(true)
        expect(system.direct_constraint_exists?("service_a", "service_b")).to be(true)
      end

      it "raises error for invalid availability constraints" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: 99.0
            depends_on: ["service_b"]
          - service: "service_b"
            availability: 95.0
        YAML

        expect {
          described_class.parse_yaml(yaml_content)
        }.to raise_error(/Invalid availability constraint/)
      end
    end

    context "with invalid YAML format" do
      it "handles empty YAML" do
        yaml_content = ""

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(0)
        expect(system.constraints.length).to eq(0)
      end

      it "handles YAML with no services" do
        yaml_content = <<~YAML
          - some_other_key: "value"
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(0)
        expect(system.constraints.length).to eq(0)
      end

      it "ignores dependencies without a service definition" do
        yaml_content = <<~YAML
          - depends_on: ["service_b"]
          - service: "service_a"
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(1)
        expect(system.constraints.length).to eq(0)
        expect(system.component_exists?("service_a")).to be(true)
      end
    end

    context "with edge cases" do
      it "handles duplicate service definitions" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: ["service_b"]
          - service: "service_a"
            depends_on: ["service_c"]
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(2) # service_a defined twice
        expect(system.constraints.length).to eq(2)
        expect(system.direct_constraint_exists?("service_a", "service_b")).to be(true)
        expect(system.direct_constraint_exists?("service_a", "service_c")).to be(true)
      end

      it "handles self-referencing dependencies" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: ["service_a"]
        YAML

        expect {
          described_class.parse_yaml(yaml_content)
        }.to raise_error("Origin and dependent must be different")
      end

      it "handles dependencies on undefined services" do
        yaml_content = <<~YAML
          - service: "service_a"
            depends_on: ["undefined_service"]
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(1)
        expect(system.constraints.length).to eq(1)
        expect(system.direct_constraint_exists?("service_a", "undefined_service")).to be(true)
      end

      it "handles duplicate service definitions with different availabilities" do
        yaml_content = <<~YAML
          - service: "service_a"
            availability: 95.0
          - service: "service_a"
            availability: 99.0
        YAML

        system = described_class.parse_yaml(yaml_content)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(2) # Both components are created
        # Both availabilities should be preserved
        availabilities = system.components.map(&:availability)
        expect(availabilities).to contain_exactly(95.0, 99.0)
      end
    end
  end

  describe ".parse_file" do
    it "reads and parses a YAML file" do
      # Create a temporary file for testing
      require "tempfile"

      yaml_content = <<~YAML
        - service: "service_a"
          depends_on: ["service_b"]
        - service: "service_b"
      YAML

      Tempfile.create(["test_system", ".yml"]) do |file|
        file.write(yaml_content)
        file.rewind

        system = described_class.parse_file(file.path)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(2)
        expect(system.constraints.length).to eq(1)
        expect(system.component_exists?("service_a")).to be(true)
        expect(system.component_exists?("service_b")).to be(true)
        expect(system.direct_constraint_exists?("service_a", "service_b")).to be(true)
      end
    end

    it "reads and parses a YAML file with availability attributes" do
      require "tempfile"

      yaml_content = <<~YAML
        - service: "service_a"
          availability: 95.0
          depends_on: ["service_b"]
        - service: "service_b"
          availability: 99.5
      YAML

      Tempfile.create(["test_system_with_availability", ".yml"]) do |file|
        file.write(yaml_content)
        file.rewind

        system = described_class.parse_file(file.path)

        expect(system).to be_a(Agtron::System)
        expect(system.components.length).to eq(2)
        expect(system.component_by_name("service_a").availability).to eq(95.0)
        expect(system.component_by_name("service_b").availability).to eq(99.5)
        expect(system.valid?).to be(true)
      end
    end
  end
end
