module Agtron
  # A constraint expresses a relationship between two components.
  class Constraint
    CONSTRAINT_HARD = "hard"
    CONSTRAINT_SOFT = "soft"
    CONSTRAINT_TYPES = [CONSTRAINT_HARD, CONSTRAINT_SOFT]

    attr_reader :type, :origin, :dependent

    def initialize(type, origin, dependent)
      validate_type!(type)
      non_nil_components!(origin, dependent)
      no_self_loop!(origin, dependent)

      @type = type
      @origin = origin
      @dependent = dependent
    end

    private

    def validate_type!(type)
      raise "Invalid constraint type: #{type}" unless CONSTRAINT_TYPES.include?(type)
    end

    def non_nil_components!(origin, dependent)
      raise "Origin and dependent must be non-nil" if origin.nil? || dependent.nil?
    end

    def no_self_loop!(origin, dependent)
      raise "Origin and dependent must be different" if origin == dependent
    end
  end
end
