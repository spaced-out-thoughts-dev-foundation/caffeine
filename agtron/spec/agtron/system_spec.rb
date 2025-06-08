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

    it "raises an error for invalid availability constraints" do
      components = [
        Agtron::Component.new("A", 99.0),
        Agtron::Component.new("B", 95.0)
      ]
      constraints = [
        Agtron::Constraint.new("hard", "A", "B")
      ]

      expect {
        Agtron::System.new(components, constraints)
      }.to raise_error(/Invalid availability constraint: A \(99.0\) depends on B \(95.0\)/)
    end

    it "does not raise an error for valid availability constraints" do
      components = [
        Agtron::Component.new("A", 95.0),
        Agtron::Component.new("B", 99.0)
      ]
      constraints = [
        Agtron::Constraint.new("hard", "A", "B")
      ]

      expect {
        Agtron::System.new(components, constraints)
      }.not_to raise_error
    end

    it "raises an error for invalid availability constraints in a more complex system" do
      components = [
        Agtron::Component.new("A", 99.9),
        Agtron::Component.new("B", 99.9),
        Agtron::Component.new("C", "unknown"),
        Agtron::Component.new("D", 99.0)
      ]
      constraints = [
        Agtron::Constraint.new("hard", "A", "B"),
        Agtron::Constraint.new("hard", "B", "C"),
        Agtron::Constraint.new("hard", "C", "D")
      ]

      expect {
        Agtron::System.new(components, constraints)
      }.to raise_error(/Invalid availability constraint: A \(99.9\) depends on D \(99.0\)/)
    end

    it "does not raise an error for valid availability constraints with unknown fallthrough" do
      components = [
        Agtron::Component.new("A", 99.9),
        Agtron::Component.new("B", 99.9),
        Agtron::Component.new("C", "unknown"),
        Agtron::Component.new("D", 99.99)
      ]
      constraints = [
        Agtron::Constraint.new("hard", "A", "B"),
        Agtron::Constraint.new("hard", "B", "C"),
        Agtron::Constraint.new("hard", "C", "D")
      ]

      expect {
        Agtron::System.new(components, constraints)
      }.not_to raise_error
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

    context "with availability constraints" do
      it "returns true for valid availability chain with unknown fallthrough" do
        # A(99%) -> B(unknown) -> C(99.9%) -> D(99.9%)
        system.add_component(Agtron::Component.new("A", 99.0))
        system.add_component(Agtron::Component.new("B", "unknown"))
        system.add_component(Agtron::Component.new("C", 99.9))
        system.add_component(Agtron::Component.new("D", 99.9))

        system.add_constraint(Agtron::Constraint.new("hard", "A", "B"))
        system.add_constraint(Agtron::Constraint.new("hard", "B", "C"))
        system.add_constraint(Agtron::Constraint.new("hard", "C", "D"))

        expect(system.valid?).to be(true)
      end

      it "raises error for invalid availability chain with unknown fallthrough" do
        # A(99.95%) -> B(unknown) -> C(99.9%) -> D(99.9%)
        system.add_component(Agtron::Component.new("A", 99.95))
        system.add_component(Agtron::Component.new("B", "unknown"))
        system.add_component(Agtron::Component.new("C", 99.9))
        system.add_component(Agtron::Component.new("D", 99.9))

        system.add_constraint(Agtron::Constraint.new("hard", "A", "B"))

        expect {
          system.add_constraint(Agtron::Constraint.new("hard", "B", "C"))
        }.to raise_error(/Invalid availability constraint: A \(99.95\) depends on C \(99.9\)/)
      end

      it "returns true when component has unknown availability" do
        # A(unknown) -> B(50%) is valid because A is unknown
        system.add_component(Agtron::Component.new("A", "unknown"))
        system.add_component(Agtron::Component.new("B", 50.0))

        system.add_constraint(Agtron::Constraint.new("hard", "A", "B"))

        expect(system.valid?).to be(true)
      end

      it "returns true for valid direct dependency relationship" do
        # A(95%) -> B(99%) is valid
        system.add_component(Agtron::Component.new("A", 95.0))
        system.add_component(Agtron::Component.new("B", 99.0))

        system.add_constraint(Agtron::Constraint.new("hard", "A", "B"))

        expect(system.valid?).to be(true)
      end

      it "raises error for invalid direct dependency relationship" do
        # A(99%) -> B(95%) is invalid
        system.add_component(Agtron::Component.new("A", 99.0))
        system.add_component(Agtron::Component.new("B", 95.0))

        expect {
          system.add_constraint(Agtron::Constraint.new("hard", "A", "B"))
        }.to raise_error(/Invalid availability constraint: A \(99.0\) depends on B \(95.0\)/)
      end

      it "returns true for equal availability" do
        # A(95%) -> B(95%) is valid
        system.add_component(Agtron::Component.new("A", 95.0))
        system.add_component(Agtron::Component.new("B", 95.0))

        system.add_constraint(Agtron::Constraint.new("hard", "A", "B"))

        expect(system.valid?).to be(true)
      end

      it "handles mixed string and component constraints" do
        # Components with dependencies on string names (not Component objects)
        system.add_component(Agtron::Component.new("service_a", 95.0))

        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))

        expect(system.valid?).to be(true)
      end
    end
  end

  describe "#recommend_availability_range" do
    context "with no constraints" do
      it "returns default range [0, 100] for component with no dependencies or dependents" do
        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 0, max: 100})
      end
    end

    context "with direct dependencies only" do
      it "returns range with max constrained by dependencies" do
        system.add_component(Agtron::Component.new("service_b", 95.0))
        system.add_component(Agtron::Component.new("service_c", 90.0))

        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_c"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 0, max: 90.0})
      end

      it "ignores unknown availability dependencies" do
        system.add_component(Agtron::Component.new("service_b", 95.0))
        system.add_component(Agtron::Component.new("service_c", "unknown"))

        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_c"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 0, max: 95.0})
      end

      it "returns max 100 when all dependencies are unknown" do
        system.add_component(Agtron::Component.new("service_b", "unknown"))

        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 0, max: 100})
      end

      it "handles string dependencies that are not components" do
        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "external_service"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 0, max: 100})
      end
    end

    context "with direct dependents only" do
      it "returns range with min constrained by dependents" do
        system.add_component(Agtron::Component.new("service_b", 85.0))
        system.add_component(Agtron::Component.new("service_c", 90.0))

        system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_a"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_c", "service_a"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 90.0, max: 100})
      end

      it "ignores unknown availability dependents" do
        system.add_component(Agtron::Component.new("service_b", 85.0))
        system.add_component(Agtron::Component.new("service_c", "unknown"))

        system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_a"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_c", "service_a"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 85.0, max: 100})
      end

      it "returns min 0 when all dependents are unknown" do
        system.add_component(Agtron::Component.new("service_b", "unknown"))

        system.add_constraint(Agtron::Constraint.new("hard", "service_b", "service_a"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 0, max: 100})
      end

      it "handles string dependents that are not components" do
        system.add_constraint(Agtron::Constraint.new("hard", "external_service", "service_a"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 0, max: 100})
      end
    end

    context "with both dependencies and dependents" do
      it "returns range constrained by both sides" do
        system.add_component(Agtron::Component.new("service_x", 80.0))
        system.add_component(Agtron::Component.new("service_y", 85.0))
        system.add_component(Agtron::Component.new("service_b", 95.0))
        system.add_component(Agtron::Component.new("service_c", 90.0))

        system.add_constraint(Agtron::Constraint.new("hard", "service_x", "service_a"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_y", "service_a"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_c"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 85.0, max: 90.0})
      end

      it "returns invalid range when constraints are impossible" do
        system.add_component(Agtron::Component.new("service_x", 95.0))
        system.add_component(Agtron::Component.new("service_b", 80.0))

        system.instance_variable_get(:@constraints) << Agtron::Constraint.new("hard", "service_x", "service_a")
        system.instance_variable_get(:@constraints) << Agtron::Constraint.new("hard", "service_a", "service_b")

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 95.0, max: 80.0})
      end

      it "handles mixed unknown availabilities" do
        system.add_component(Agtron::Component.new("service_x", 80.0))
        system.add_component(Agtron::Component.new("service_y", "unknown"))
        system.add_component(Agtron::Component.new("service_b", "unknown"))
        system.add_component(Agtron::Component.new("service_c", 90.0))

        system.add_constraint(Agtron::Constraint.new("hard", "service_x", "service_a"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_y", "service_a"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_b"))
        system.add_constraint(Agtron::Constraint.new("hard", "service_a", "service_c"))

        range = system.recommend_availability_range("service_a")
        expect(range).to eq({min: 80.0, max: 90.0})
      end
    end
  end
end
