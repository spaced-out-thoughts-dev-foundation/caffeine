module Agtron
  # A system is a collection of components and constraints.
  class System
    def initialize(components, constraints)
      @components = components
      @constraints = constraints
    end
  end
end
