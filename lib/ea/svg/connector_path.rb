# frozen_string_literal: true

module Ea
  module Svg
    # Renders one DiagramConnector as an SVG <path> through its
    # waypoints, with an arrowhead at the target end. Matches EA's
    # convention: filled triangle for navigable associations, filled
    # diamond for aggregations, open diamond for shared aggregations.
    class ConnectorPath
      ARROW_SIZE = 8

      attr_reader :connector, :relationship

      def initialize(connector, relationship: nil)
        @connector = connector
        @relationship = relationship
      end

      def render
        points = waypoints
        return "" if points.size < 2

        path_d = build_path_d(points)
        style = StyleResolver.new(connector.style)

        parts = []
        parts << %(<g class="connector" data-connector-id="#{escape(connector.id)}">)
        parts << %(  <path d="#{path_d}" stroke="#{style.stroke_color}" stroke-width="#{style.stroke_width}" fill="none"/>)
        parts << render_source_marker(points) if source_marker?
        parts << render_target_marker(points)
        parts << %(</g>)
        parts.join("\n            ")
      end

      private

      def waypoints
        connector.waypoints.filter_map do |wp|
          next unless wp.position

          [wp.position.x, wp.position.y]
        end
      end

      def build_path_d(points)
        moves = points.each_with_index.map do |p, idx|
          prefix = idx.zero? ? "M" : "L"
          "#{prefix} #{p[0]} #{p[1]}"
        end
        moves.join(" ")
      end

      def source_marker?
        return false unless relationship

        relationship.is_a?(Ea::Model::Association) &&
          relationship.source_aggregation != "none"
      end

      def render_source_marker(points)
        case relationship.source_aggregation
        when "composite" then filled_diamond(points.first, points[1])
        when "shared" then open_diamond(points.first, points[1])
        else ""
        end
      end

      def render_target_marker(points)
        filled_arrow(points.last, points[-2])
      end

      def filled_arrow(tip, base)
        return "" unless tip && base

        # Build a triangle pointing from base toward tip
        bx, by = base
        tx, ty = tip
        # Perpendicular vector for the wings
        dx = tx - bx
        dy = ty - by
        len = Math.sqrt(dx * dx + dy * dy)
        return "" if len.zero?

        ux = dx / len
        uy = dy / len
        # Wing points are ARROW_SIZE back from tip, perpendicular
        back_x = tx - ux * ARROW_SIZE
        back_y = ty - uy * ARROW_SIZE
        perp_x = -uy * (ARROW_SIZE / 2.0)
        perp_y = ux * (ARROW_SIZE / 2.0)
        w1_x = back_x + perp_x
        w1_y = back_y + perp_y
        w2_x = back_x - perp_x
        w2_y = back_y - perp_y
        points_str = "#{tx} #{ty} #{w1_x.round(1)} #{w1_y.round(1)} #{w2_x.round(1)} #{w2_y.round(1)}"
        %(  <polygon points="#{points_str}" fill="black" stroke="black" stroke-width="1"/>)
      end

      def filled_diamond(tip, base)
        diamond_polygon(tip, base, fill: "black")
      end

      def open_diamond(tip, base)
        diamond_polygon(tip, base, fill: "white")
      end

      def diamond_polygon(tip, base, fill:)
        bx, by = base
        tx, ty = tip
        dx = tx - bx
        dy = ty - by
        len = Math.sqrt(dx * dx + dy * dy)
        return "" if len.zero?

        ux = dx / len
        uy = dy / len
        back_x = tx - ux * ARROW_SIZE
        back_y = ty - uy * ARROW_SIZE
        perp_x = -uy * (ARROW_SIZE / 2.0)
        perp_y = ux * (ARROW_SIZE / 2.0)
        far_x = tx - ux * (2 * ARROW_SIZE)
        far_y = ty - uy * (2 * ARROW_SIZE)
        w1_x = back_x + perp_x
        w1_y = back_y + perp_y
        w2_x = back_x - perp_x
        w2_y = back_y - perp_y
        points_str = "#{far_x.round(1)} #{far_y.round(1)} #{w1_x.round(1)} #{w1_y.round(1)} #{tx} #{ty} #{w2_x.round(1)} #{w2_y.round(1)}"
        %(  <polygon points="#{points_str}" fill="#{fill}" stroke="black" stroke-width="1"/>)
      end

      def escape(text)
        return "" if text.nil?

        text.to_s.gsub("\"", "&quot;")
      end
    end
  end
end
