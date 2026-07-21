# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits the connectors layer: for each DiagramConnector, emits
      # one <g> containing the <path d="M x y L x2 y2..."/> through
      # its waypoints. Markers (arrowheads, diamonds) are emitted
      # separately by the Markers emitter.
      class Connectors
        attr_reader :diagram, :canvas

        def initialize(diagram, canvas: nil)
          @diagram = diagram
          @canvas = canvas
        end

        def render
          paths = visible_connectors.filter_map { |c| path_for(c) }
          return "" if paths.empty?

          %(<g style="stroke-width:2;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:0.00; stroke:#000000; stroke-opacity:1.00">\n#{paths.join("\n")}\n</g>)
        end

        private

        def visible_connectors
          (diagram.connectors || []).reject(&:hidden)
        end

        def path_for(connector)
          pts = waypoints_for(connector)
          return nil if pts.size < 2

          d = pts.each_with_index.map do |p, idx|
            x, y = translate_point(p)
            "#{idx.zero? ? 'M' : 'L'} #{format('%.2f', x)} #{format('%.2f', y)}"
          end.join(" ")
          %(  <path d="#{d}" shape-rendering="auto"/>)
        end

        def waypoints_for(connector)
          (connector.waypoints || []).filter_map do |wp|
            next unless wp.position

            [wp.position.x, wp.position.y]
          end
        end

        def translate_point(p)
          return p unless canvas

          [canvas.translate_x(p[0]), canvas.translate_y(p[1])]
        end
      end
    end
  end
end
