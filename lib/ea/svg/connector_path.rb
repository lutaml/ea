# frozen_string_literal: true

module Ea
  module Svg
    # Renders one DiagramConnector as an SVG <polyline> through
    # its waypoints. Arrowheads and per-direction routing are
    # future work; today we emit a straight-segment polyline
    # matching the source layout.
    class ConnectorPath
      attr_reader :connector

      def initialize(connector)
        @connector = connector
      end

      def render
        points = waypoints
        return "" if points.empty?

        <<~SVG.chomp
          <polyline points="#{points.join(' ')}"
                    fill="none" stroke="#{stroke_color}"
                    stroke-width="#{stroke_width}"/>
        SVG
      end

      private

      def waypoints
        connector.waypoints.filter_map do |wp|
          next unless wp.position

          "#{wp.position.x},#{wp.position.y}"
        end
      end

      def stroke_color
        StyleResolver.new(connector.style).stroke_color
      end

      def stroke_width
        StyleResolver.new(connector.style).stroke_width
      end
    end
  end
end
