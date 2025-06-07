module Agtron
  # A system is a collection of components and constraints.
  class System
    attr_reader :components, :constraints

    def initialize(components, constraints)
      raise "Invalid system: components and constraints must be non-nil" if components.nil? || constraints.nil?

      @components = components
      @constraints = constraints

      raise "Cyclic dependency detected" unless acyclic?
    end

    def add_component(component)
      @components << component
    end

    def add_constraint(constraint)
      @constraints << constraint
      raise "Cyclic dependency detected" unless acyclic?
    end

    def component_exists?(name)
      component_by_name(name) != nil
    end

    def component_by_name(name)
      @components.find { |component| component.name == name }
    end

    def direct_constraint_exists?(origin, dependent)
      @constraints.any? { |constraint| constraint.origin == origin && constraint.dependent == dependent }
    end

    def direct_constraint_by_origin_and_dependent(origin, dependent)
      @constraints.find { |constraint| constraint.origin == origin && constraint.dependent == dependent }
    end

    # A valid system is one where there are no cycles in the graph.
    def acyclic?
      # Get all unique nodes from constraints
      nodes = Set.new
      @constraints.each do |constraint|
        nodes.add(constraint.origin)
        nodes.add(constraint.dependent)
      end

      # Build adjacency list
      graph = Hash.new { |h, k| h[k] = [] }
      @constraints.each do |constraint|
        graph[constraint.origin] << constraint.dependent
      end

      # DFS with recursion stack to detect cycles
      visited = Set.new
      rec_stack = Set.new

      nodes.each do |node|
        next if visited.include?(node)
        return false if has_cycle_dfs(node, graph, visited, rec_stack)
      end

      true
    end

    def valid?
      acyclic?
    end

    # traverse entire graph to see if there is a path from origin to dependent
    def indirect_constraint_exists?(origin, dependent)
      return false if origin == dependent
      return true if direct_constraint_exists?(origin, dependent)

      visited = Set.new
      dfs_path_exists(origin, dependent, visited)
    end

    def constraint_path(origin, dependent)
      return [] if origin == dependent

      visited = Set.new
      all_paths = []
      current_path = [origin]

      find_all_paths(origin, dependent, visited, current_path, all_paths)

      (all_paths.length == 1) ? all_paths.first : all_paths
    end

    private

    def has_cycle_dfs(node, graph, visited, rec_stack)
      visited.add(node)
      rec_stack.add(node)

      graph[node].each do |neighbor|
        if !visited.include?(neighbor)
          return true if has_cycle_dfs(neighbor, graph, visited, rec_stack)
        elsif rec_stack.include?(neighbor)
          return true
        end
      end

      rec_stack.delete(node)
      false
    end

    def dfs_path_exists(current, target, visited)
      return false if visited.include?(current)
      visited.add(current)

      @constraints.each do |constraint|
        if constraint.origin == current
          if constraint.dependent == target
            return true
          elsif dfs_path_exists(constraint.dependent, target, visited)
            return true
          end
        end
      end

      false
    end

    def find_all_paths(current, target, visited, current_path, all_paths)
      return if visited.include?(current)
      return if current_path.length > 10 # Prevent extremely long paths

      if current == target && current_path.length > 1
        all_paths << current_path.dup
        return
      end

      visited.add(current)

      @constraints.each do |constraint|
        if constraint.origin == current
          current_path << constraint.dependent
          find_all_paths(constraint.dependent, target, visited, current_path, all_paths)
          current_path.pop
        end
      end

      visited.delete(current)
    end
  end
end
