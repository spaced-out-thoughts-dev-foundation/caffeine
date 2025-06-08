#!/usr/bin/env ruby

require_relative "lib/agtron"

# Load the example system from YAML
system = Agtron::Parser.parse_file("example_system.yml")

puts "=== System Analysis ==="
puts "Components: #{system.components.length}"
puts "Constraints: #{system.constraints.length}"
puts "Valid: #{system.valid?}"
puts "Acyclic: #{system.acyclic?}"

puts "\n=== Components ==="
system.components.each do |component|
  puts "- #{component.name} (availability: #{component.availability})"
end

puts "\n=== Constraints ==="
system.constraints.each do |constraint|
  puts "- #{constraint.origin} -> #{constraint.dependent} (#{constraint.type})"
end

puts "\n=== Dependency Analysis ==="
puts "service_a depends on service_c: #{system.indirect_constraint_exists?("service_a", "service_c")}"
puts "Path from service_a to service_c: #{system.constraint_path("service_a", "service_c")}"
puts "Path from service_a to service_d: #{system.constraint_path("service_a", "service_d")}"

puts "\n=== Availability Recommendations ==="
puts "service_a range: #{system.recommend_availability_range("service_a")}"
puts "service_b range: #{system.recommend_availability_range("service_b")}"
puts "service_c range: #{system.recommend_availability_range("service_c")}"
puts "service_d range: #{system.recommend_availability_range("service_d")}"
