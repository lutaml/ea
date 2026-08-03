# frozen_string_literal: true

module Ea
  module Lint
    module Rules
      # Detects cyclic generalization chains (A → B → A).
      class CyclicGeneralizationRule < LintRule
        self.severity = :error

        def check(model)
          graph = build_graph(model)
          cycles = find_cycles(graph)
          cycles.map do |cycle|
            offense(entity_id: cycle.first,
                    entity_name: cycle.join(" → "),
                    message: "Cyclic generalization: #{cycle.join(' → ')} → #{cycle.first}")
          end
        end

        private

        def build_graph(model)
          graph = {}
          (model.collections[:connectors] || []).each do |conn|
            next unless conn.connector_type == "Generalization"

            from = conn.start_object_id
            to = conn.end_object_id
            graph[from] ||= []
            graph[from] << to
          end
          graph
        end

        def find_cycles(graph)
          cycles = []
          visited = Set.new

          graph.each_key do |start|
            next if visited.include?(start)

            dfs(graph, start, [start], Set.new([start]), cycles, visited)
          end
          cycles
        end

        def dfs(graph, node, path, on_path, cycles, visited)
          (graph[node] || []).each do |neighbor|
            if on_path.include?(neighbor)
              idx = path.index(neighbor)
              cycles << path[idx..] + [neighbor] if idx
            elsif !visited.include?(neighbor)
              dfs(graph, neighbor, path + [neighbor],
                  on_path + [neighbor], cycles, visited)
            end
          end
          visited.add(node)
        end
      end
    end
  end
end
