# frozen_string_literal: true

require "ostruct"

module Ea
  module Svg
    # Renders an Ea::Model::Diagram into a standalone SVG string.
    # Coordinates come straight from the umldi (UML Diagram
    # Interchange) content captured by the source adapter:
    # DiagramElement bounds and DiagramConnector waypoints.
    #
    # The renderer walks the diagram once, computes the union
    # bounding box, and emits SVG in the same coordinate space
    # (no y-flip; SVG's +y is down, same as EA's pixel space).
    class Renderer
      DEFAULT_PADDING = 20

      attr_reader :diagram, :model_index, :options

      def initialize(diagram, model_index: {}, padding: DEFAULT_PADDING)
        @diagram = diagram
        @model_index = model_index
        @options = { padding: padding }
      end

      def render
        bounds = BoundsCalculator.new(diagram).compute
        padded = pad(bounds)

        <<~SVG
          <?xml version="1.0" encoding="UTF-8"?>
          <svg xmlns="http://www.w3.org/2000/svg"
               viewBox="#{padded.x} #{padded.y} #{padded.width} #{padded.height}"
               width="#{padded.width}" height="#{padded.height}"
               font-family="sans-serif">
            <rect x="#{padded.x}" y="#{padded.y}"
                  width="#{padded.width}" height="#{padded.height}"
                  fill="white"/>
            #{render_elements}
            #{render_connectors}
          </svg>
        SVG
      end

      private

      def render_elements
        diagram.elements.map do |elem|
          ElementBox.new(elem, model_index: model_index).render
        end.join("\n            ")
      end

      def render_connectors
        diagram.connectors.map do |conn|
          ConnectorPath.new(conn).render
        end.join("\n            ")
      end

      def pad(bounds)
        p = options[:padding]
        OpenStruct.new(
          x: bounds.x - p,
          y: bounds.y - p,
          width: bounds.width + (2 * p),
          height: bounds.height + (2 * p)
        )
      end
    end
  end
end
