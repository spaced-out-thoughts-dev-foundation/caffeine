module Agtron
  # A component is a named entity within a system that may exist as a constraint origin or dependent.
  class Component
    attr_reader :name, :availability

    def initialize(name, availability)
      validate_availability!(availability)

      @name = name
      @availability = availability
    end

    private

    def validate_availability!(availability)
      unless availability.is_a?(Numeric) || availability == "unknown"
        raise "Availability must be a number or 'unknown'"
      end
    end
  end
end
