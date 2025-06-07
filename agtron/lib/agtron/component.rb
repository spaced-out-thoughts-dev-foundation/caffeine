module Agtron
  # A component is a named entity within a system that may exist as a constraint origin or dependent.
  class Component
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
