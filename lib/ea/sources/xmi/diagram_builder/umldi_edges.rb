# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      class DiagramBuilder
        # The UMLDI edge EA exported for a connector on a diagram: its
        # ordered waypoints and its source/target model elements. A connector
        # drawn by more than one edge in the same diagram has neither; an edge
        # with fewer than two waypoints has no route.
        class UmldiEdges
          def initialize(xmi_path)
            @xmi_path = xmi_path
          end

          def route_for(diagram_id, connector_id)
            routes.dig(diagram_id, connector_id)
          end

          def ends_for(diagram_id, connector_id)
            ends.dig(diagram_id, connector_id)
          end

          private

          def ends
            @ends ||= doc.xpath("//*[local-name()=\"Diagram\"]").to_h do |diagram|
              [diagram["id"] || diagram["xmi:id"], diagram_ends(diagram)]
            end
          end

          def diagram_ends(diagram)
            unique_edges(diagram).each_with_object({}) do |(connector_id, edge), acc|
              acc[connector_id] = [edge["source"], edge["target"]] if edge["source"] && edge["target"]
            end
          end

          # Edges keyed by connector, keeping only connectors drawn by exactly
          # one edge of the diagram, whatever that edge carries.
          def unique_edges(diagram)
            diagram.xpath("./ownedElement[@modelElement]")
                   .select { |node| node.attributes["type"]&.value.to_s.end_with?("UMLEdge") }
                   .group_by { |edge| edge["modelElement"] }
                   .select { |_, same| same.one? }
                   .transform_values(&:first)
          end

          def routes
            @routes ||= doc.xpath("//*[local-name()=\"Diagram\"]").to_h do |diagram|
              [diagram["id"] || diagram["xmi:id"], diagram_routes(diagram)]
            end
          end

          def diagram_routes(diagram)
            unique_edges(diagram).each_with_object({}) do |(connector_id, edge), acc|
              points = waypoints(edge)
              acc[connector_id] = points if points.size >= 2
            end
          end

          def waypoints(edge)
            edge.xpath("./waypoint").map { |point| [Integer(point["x"]), Integer(point["y"])] }
          end

          def doc
            Nokogiri::XML(File.read(@xmi_path))
          end
        end
      end
    end
  end
end
