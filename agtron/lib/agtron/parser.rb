require "yaml"

module Agtron
  # A parser that can parse YAML files describing system components and constraints
  class Parser
    def self.parse_file(file_path)
      content = File.read(file_path)
      parse_yaml(content)
    end

    def self.parse_yaml(yaml_content)
      data = YAML.safe_load(yaml_content, permitted_classes: [Symbol])
      parse_data(data)
    end

    def self.parse_data(data)
      components = []
      constraints = []

      # Handle empty or nil data
      return System.new(components, constraints) if data.nil? || data.empty?

      data.each do |item|
        if item.is_a?(Hash) && item.key?("service")
          # New service definition
          service_name = item["service"]

          # Get availability, default to "unknown" if not specified
          availability = item.key?("availability") ? item["availability"] : "unknown"

          # Create component with specified or default availability
          components << Component.new(service_name, availability)

          # Handle dependencies if they exist in the same hash
          if item.key?("depends_on")
            dependencies = item["depends_on"]
            dependencies.each do |dep_name|
              constraints << Constraint.new("hard", service_name, dep_name)
            end
          end
        end
      end

      System.new(components, constraints)
    end

    private_class_method :parse_data
  end
end
