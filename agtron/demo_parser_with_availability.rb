#!/usr/bin/env ruby

require_relative "lib/agtron"

# Load the example system with availability attributes from YAML
system = Agtron::Parser.parse_file("example_system_with_availability.yml")

puts "=== System Analysis ==="
puts "Components: #{system.components.length}"
puts "Constraints: #{system.constraints.length}"
puts "Valid: #{system.valid?}"
puts "Acyclic: #{system.acyclic?}"

puts "\n=== Components with Availability ==="
system.components.each do |component|
  puts "- #{component.name}: #{component.availability}%"
end

puts "\n=== Constraints ==="
system.constraints.each do |constraint|
  puts "- #{constraint.origin} -> #{constraint.dependent} (#{constraint.type})"
end

puts "\n=== Dependency Analysis ==="
puts "web_frontend depends on user_database: #{system.indirect_constraint_exists?("web_frontend", "user_database")}"
puts "Path from web_frontend to user_database: #{system.constraint_path("web_frontend", "user_database")}"

puts "\n=== Availability Recommendations ==="
["web_frontend", "api_gateway", "user_service", "order_service", "payment_service"].each do |service|
  range = system.recommend_availability_range(service)
  puts "#{service}: #{range[:min]}% - #{range[:max]}%"

  if range[:min] > range[:max]
    puts "  ⚠️  WARNING: Impossible constraints detected!"
  end
end

puts "\n=== Availability Constraint Validation ==="
begin
  puts "All availability constraints are valid: #{system.valid?}"
rescue => e
  puts "❌ Validation failed: #{e.message}"
end
