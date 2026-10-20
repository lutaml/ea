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

          # Absolute saved UMLDI bounds for connector label boxes. These are
          # kept separate from extension label offsets: callers may use them
          # only when the extension did not save label geometry.
          def label_bounds_for(diagram_id, connector_id)
            label_bounds.dig(diagram_id, connector_id)
          end

          private

          def ends
            @ends ||= doc.xpath("//*[local-name()=\"Diagram\"]").to_h do |diagram|
              [diagram["id"] || diagram["xmi:id"], diagram_ends(diagram)]
            end
          end

          def label_bounds
            @label_bounds ||= doc.xpath("//*[local-name()=\"Diagram\"]").to_h do |diagram|
              [diagram["id"] || diagram["xmi:id"], diagram_label_bounds(diagram)]
            end
          end

          def diagram_label_bounds(diagram)
            boxes_by_connector = unique_edges(diagram).to_h do |connector_id, edge|
              [connector_id, edge_label_bounds(edge)]
            end
            boxes_by_connector.reject { |_, boxes| boxes.empty? }
          end

          def edge_label_bounds(edge)
            edge.xpath("./ownedElement[@modelElement]").each_with_object({}) do |label, found|
              bounds = label.at_xpath("./*[local-name()=\"bounds\"]")
              key = label_key(label)
              next unless key && bounds

              found[key] = bounds_values(bounds)
            rescue ArgumentError, TypeError
              next
            end
          end

          def bounds_values(bounds)
            %w[x y width height].to_h { |attribute| [attribute.to_sym, Integer(bounds[attribute])] }
          end

          def label_key(label)
            type = label.attributes["type"]&.value.to_s
            role = (label["id"] || label["xmi:id"]).to_s
            end_name = { "EAID_SEL" => "source", "EAID_SML" => "source",
                         "EAID_TEL" => "target", "EAID_TML" => "target" }
            side = end_name.find { |prefix, _| role.start_with?(prefix) }&.last
            suffix = { "UMLAssociationEndLabel" => "role", "UMLMultiplicityLabel" => "multiplicity" }
            label_kind = suffix[type.split(":").last]
            "#{side}_#{label_kind}".to_sym if side && label_kind
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
