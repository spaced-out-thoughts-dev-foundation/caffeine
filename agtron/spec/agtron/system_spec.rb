require "spec_helper"

RSpec.describe Agtron::System do
  let(:system) { Agtron::System.new([], []) }

  describe "#initialize" do
    it "raises an error when initializing with cycles" do
      constraints = [
        Agtron::Constraint.new("hard", "service_a", "service_b"),
        Agtron::Constraint.new("hard", "service_b", "service_c"),
        Agtron::Constraint.new("hard", "service_c", "service_a")
      ]

      expect {
        Agtron::System.new([], constraints)
      }.to raise_error("Cyclic dependency detected")
    end

    it "does not raise an error for acyclic constraints" do
      constraints = [
        Agtron::Constraint.new("hard", "service_a", "service_b"),
        Agtron::Constraint.new("hard", "service_b", "service_c"),
        Agtron::Constraint.new("hard", "service_a", "service_d")
      ]

      expect {
        Agtron::System.new([], constraints)
      }.not_to raise_error
    end

    it "raises an error for nil components" do
      expect {
        Agtron::System.new(nil, [])
      }.to raise_error("Invalid system: components and constraints must be non-nil")
    end

    it "raises an error for nil constraints" do
      expect {
        Agtron::System.new([], nil)
      }.to raise_error("Invalid system: components and constraints must be non-nil")
    end
  end

  describe "#add_component" do
    it "adds a component to the system" do
      system.add_component(Agtron::Component.new("service_a", 90))
      expect(system.component_exists?("service_a")).to be(true)
    end

    it "adds a component with unknown availability to the system" do
      system.add_component(Agtron::Component.new("service_b", "unknown"))
      expect(system.component_exists?("service_b")).to be(true)
      expect(system.component_by_name("service_b").availability).to eq("unknown")
    end
  end

  describe "#add_constraint" do
    it "adds a constraint to the system" do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      expect(system.constraints.length).to eq(1)
    end

    it "raises an error when adding a constraint that creates a cycle" do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_c"))

      expect {
        system.add_constraint(Agtron::Constraint.new("hard", "service_c", "service_a"))
      }.to raise_error("Cyclic dependency detected")
    end
  end

  describe "#component_exists?" do
    it "returns false when component does not exist" do
      expect(system.component_exists?("service_a")).to be(false)
    end

    it "returns true when component exists" do
      system.add_component(Agtron::Component.new("service_a", 85))
      expect(system.component_exists?("service_a")).to be(true)
    end
  end

  describe "#component_by_name" do
    it "returns nil when component does not exist" do
      expect(system.component_by_name("service_a")).to be(nil)
    end

    it "returns the component when it exists" do
      component = Agtron::Component.new("service_a", 75)
      system.add_component(component)
      expect(system.component_by_name("service_a")).to eq(component)
    end

    it "returns the component with unknown availability when it exists" do
      component = Agtron::Component.new("service_unknown", "unknown")
      system.add_component(component)
      expect(system.component_by_name("service_unknown")).to eq(component)
      expect(system.component_by_name("service_unknown").availability).to eq("unknown")
    end
  end

  describe "#direct_constraint_exists?" do
    it "returns true when direct constraint exists" do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      expect(system.direct_constraint_exists?("service_a", "service_b")).to be(true)
    end

    it "returns false when direct constraint does not exist" do
      expect(system.direct_constraint_exists?("service_a", "service_b")).to be(false)
    end
  end

  describe "#direct_constraint_by_origin_and_dependent" do
    it "returns the constraint when it exists" do
      constraint = Agtron::Constraint.new("hard", "service_a", "service_b")
      system.add_constraint(constraint)
      expect(system.direct_constraint_by_origin_and_dependent("service_a", "service_b")).to eq(constraint)
    end

    it "returns nil when constraint does not exist" do
      expect(system.direct_constraint_by_origin_and_dependent("service_a", "service_b")).to be(nil)
    end
  end

  describe "#indirect_constraint_exists?" do
    before do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_c"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_e"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_f"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_c", "service_d"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_q", "service_p"))
    end

    it "returns true when indirect constraint exists" do
      expect(system.indirect_constraint_exists?("service_a", "service_d")).to be(true)
      expect(system.indirect_constraint_exists?("service_a", "service_e")).to be(true)
    end

    it "returns false when indirect constraint does not exist" do
      expect(system.indirect_constraint_exists?("service_a", "service_p")).to be(false)
    end

    it "returns false for self-reference" do
      expect(system.indirect_constraint_exists?("service_a", "service_a")).to be(false)
    end
  end

  describe "#constraint_path" do
    it "returns the path between two direct components" do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      expect(system.constraint_path("service_a", "service_b")).to eq(["service_a", "service_b"])
    end

    it "returns the path between two indirect components" do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_c"))
      expect(system.constraint_path("service_a", "service_c")).to eq(["service_a", "service_b", "service_c"])
    end

    it "returns multiple paths when they exist" do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_c"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_d"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_d", "service_e"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_e"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_e", "service_f"))

      expect(system.constraint_path("service_a", "service_f")).to eq([
        ["service_a", "service_b", "service_e", "service_f"],
        ["service_a", "service_d", "service_e", "service_f"]
      ])
    end

    it "returns empty array if there is no path" do
      expect(system.constraint_path("service_a", "service_d")).to eq([])
    end

    it "returns empty array for same origin and dependent" do
      expect(system.constraint_path("service_a", "service_a")).to eq([])
    end
  end

  describe "#acyclic?" do
    it "returns true for system with no constraints" do
      expect(system.acyclic?).to be(true)
    end

    it "returns true for acyclic constraints" do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_c"))
      expect(system.acyclic?).to be(true)
    end
  end

  describe "#valid?" do
    it "returns true for valid (acyclic) system" do
      system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
      expect(system.valid?).to be(true)
    end

    it "returns false for cyclic system" do
      expect {
        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_c"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_c", "service_a"))
      }.to raise_error("Cyclic dependency detected")
    end
  end
end
