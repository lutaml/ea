# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Computes the (min_x, min_y, width, height) tuple for a
      # Diagram's canvas. Encapsulates the union rules so Canvas
      # stays a small value-object with just coordinate translation
      # and formatting concerns.
      #
      # Sources contributing to the bounds:
      #   - ElementBounds:    logical x-extent, logical+image y-extent
      #   - ConnectorBounds:  waypoint positions
      #   - MarkerExtent:     MARKER_EXTENT padding around end points
      #   - PackageTabExtent: extra space above Package elements for
      #                       the tab polygon (which sits above the
      #                       element's logical top).
      #
      # Each source is a method returning an Array<[x, y]> points.
      # Composing new sources = adding a method, no modification of
      # existing ones (OCP).
      class BoundsCalculator
        MARKER_EXTENT = 15
        PACKAGE_TAB_HEIGHT = 20
        # EA's canvas includes non-uniform frame insets around the
        # element content. Reverse-engineered from reference SVG
        # byte-diff: maintenance diagram has element 169x80 at
        # logical (0,0), ref canvas is 254x177 with element at
        # (35, 40). So:
        #   canvas_width  = element_width + INSET_LEFT + INSET_RIGHT
        #   canvas_height = element_height + INSET_TOP + INSET_BOTTOM
        # The top inset accommodates the frame tab + label space
        # above the element.
        INSET_LEFT = 35
        INSET_RIGHT = 50
        INSET_TOP = 40
        INSET_BOTTOM = 57

        attr_reader :diagram, :model_index

        def initialize(diagram, model_index: nil)
          @diagram = diagram
          @model_index = model_index
        end

        def compute
          points = []
          points.concat(element_points)
          points.concat(connector_points)
          points.concat(marker_points)
          points.concat(package_tab_points)
          return [0, 0, 1, 1] if points.empty?

          xs = points.map(&:first)
          ys = points.map(&:last)
          min_x = xs.min || 0
          min_y = ys.min || 0
          [
            min_x,
            min_y,
            (xs.max - min_x) + INSET_LEFT + INSET_RIGHT,
            (ys.max - min_y) + INSET_TOP + INSET_BOTTOM
          ]
        end

        private

        # Element x-extent: logical bounds only (matches EA's canvas
        # left/right exactly).
        # Element y-extent: union of logical + image_bounds (image
        # extends below bounds for shadow / image padding).
        def element_points
          pts = []
          (diagram.elements || []).each do |e|
            primary = e.bounds || e.image_bounds
            if primary
              pts << [primary.x, primary.y]
              pts << [primary.x + primary.width, primary.y + primary.height]
            end
            if e.bounds && e.image_bounds
              ib = e.image_bounds
              pts << [ib.x, ib.y]
              pts << [ib.x + ib.width, ib.y + ib.height]
            end
          end
          pts
        end

        # Package elements render with a tab polygon ABOVE the
        # element's logical top edge (height PACKAGE_TAB_HEIGHT).
        # Include those points so the canvas reserves space.
        def package_tab_points
          return [] if model_index.nil?

          pts = []
          (diagram.elements || []).each do |e|
            ref = e.model_element_ref
            next unless ref

            candidate = model_index[ref]
            next unless candidate.is_a?(Ea::Model::Package)

            primary = e.bounds || e.image_bounds
            next unless primary

            pts << [primary.x, primary.y - PACKAGE_TAB_HEIGHT]
            pts << [primary.x + primary.width, primary.y]
          end
          pts
        end

        def connector_points
          pts = []
          (diagram.connectors || []).each do |c|
            (c.waypoints || []).each do |wp|
              next unless wp.position

              pts << [wp.position.x, wp.position.y]
            end
          end
          pts
        end

        def marker_points
          pts = []
          (diagram.connectors || []).each do |c|
            waypoints = (c.waypoints || []).map(&:position).compact
            next unless waypoints.size >= 2

            source = waypoints.first
            target = waypoints.last
            pts << [source.x - MARKER_EXTENT, source.y - MARKER_EXTENT]
            pts << [source.x + MARKER_EXTENT, source.y + MARKER_EXTENT]
            pts << [target.x - MARKER_EXTENT, target.y - MARKER_EXTENT]
            pts << [target.x + MARKER_EXTENT, target.y + MARKER_EXTENT]
          end
          pts
        end
      end
    end
  end
end
