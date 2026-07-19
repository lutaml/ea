# frozen_string_literal: true

module Ea
  module Svg
    # Computes the actual drawing-area bounding box of an
    # Ea::Model::Diagram. EA stores bounds in pixel space with two
    # quirks: element rects can be inverted (rectbottom < recttop,
    # producing negative height), and elements/connectors can sit
    # outside the canvas bounds. The drawing area is the union of
    # all element rects and connector waypoint positions.
    class BoundsCalculator
      attr_reader :diagram

      def initialize(diagram)
        @diagram = diagram
      end

      def compute
        points = all_points
        return fallback_bounds if points.empty?

        xs = points.map(&:first)
        ys = points.map(&:last)
        Bounds.new(x: xs.min, y: ys.min, width: xs.max - xs.min,
                    height: ys.max - ys.min)
      end

      private

      def all_points
        points = []
        diagram.elements.each do |elem|
          next unless elem.bounds

          b = normalize_bounds(elem.bounds)
          points << [b.x, b.y]
          points << [b.x + b.width, b.y + b.height]
        end
        diagram.connectors.each do |conn|
          conn.waypoints.each do |wp|
            next unless wp.position

            points << [wp.position.x, wp.position.y]
          end
        end
        points
      end

      # EA occasionally stores inverted rects (rectbottom < recttop).
      # Normalize so width/height are non-negative.
      def normalize_bounds(bounds)
        x = bounds.x
        y = bounds.y
        w = bounds.width
        h = bounds.height
        x, w = x + w, -w if w.negative?
        y, h = y + h, -h if h.negative?
        Bounds.new(x: x, y: y, width: w, height: h)
      end

      def fallback_bounds
        return Bounds.new(x: 0, y: 0, width: 1, height: 1) unless diagram.bounds

        Bounds.new(x: diagram.bounds.x, y: diagram.bounds.y,
                    width: diagram.bounds.width.abs,
                    height: diagram.bounds.height.abs)
      end

      # Internal value type — keep private to avoid polluting the
      # Ea::Svg namespace.
      Bounds = Struct.new(:x, :y, :width, :height, keyword_init: true)
    end
  end
end
