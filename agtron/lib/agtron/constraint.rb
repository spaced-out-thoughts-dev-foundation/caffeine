module Agtron
  # A constraint expresses a relationship between two components.
  class Constraint
    CONSTRAINT_HARD = "hard"
    CONSTRAINT_SOFT = "soft"
    CONSTRAINT_TYPES = [CONSTRAINT_HARD, CONSTRAINT_SOFT]

    def initialize(name, type, origin, dependent)
      validate_type!(type)

      @name = name
      @type = type
      @origin = origin
      @dependent = dependent
    end

    private

    def validate_type!(type)
      raise "Invalid constraint type: #{type}" unless CONSTRAINT_TYPES.include?(type)
    end
  end
end
