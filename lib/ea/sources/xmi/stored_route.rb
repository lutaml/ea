# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Routes a connector that carries stored Path bends the way the QEA
      # source does, by running the QEA builder's own route helpers over
      # the same inputs (link style, bends in `x:y;` form, connector type,
      # endpoint boxes) and the same center-ray ports.
      class StoredRoute < Qea::DiagramBuilder
        Link = Struct.new(:style, :path)

        def initialize
          super(nil)
        end

        def waypoints(link:, connector_type:, source:, target:, bends:, offsets:, edge: nil)
          connector = Struct.new(:connector_type).new(connector_type)
          stored_square_route(link, connector, source, target) ||
            stored_stair_route(link, connector, source, target) ||
            level_entry(link, connector, source, target, bends, offsets) ||
            generalization(link, connector, source, target, bends, offsets, edge)
        end

        private

        # Placements here are already Ea::Model::Bounds.
        def bounds_from_rect(bounds)
          bounds
        end

        def ported?(offset)
          offset.none?(&:nil?) && offset.any?(&:nonzero?)
        end

        def level_entry(link, connector, source, target, bends, offsets)
          return unless level_entry_style?(link, connector) && bends.any?
          return unless offsets.values.all? { |offset| ported?(offset) }

          points = [port(source, offsets[:source]), *bends, port(target, offsets[:target])]
          level_entry_route(points, link, connector, source, target)
        end

        # A Generalization with stored bends takes a port where its SX/SY
        # (EX/EY) are given and the EDGE-code edge point otherwise, then the
        # QEA parent-above redock and the QEA tree/level-entry routes.
        def generalization(link, connector, source, target, bends, offsets, edge)
          return unless connector.connector_type == "Generalization" && bends.any? && edge != 2
          return if Qea::DiagramStyleParser.parse(link.style)[:mode] == "1"

          ends = { source: [source, offsets[:source]], target: [target, offsets[:target]] }
          points = ends.map { |kind, (box, offset)| end_point(box, kind, offset, edge) }
          points = [points.first, *bends, points.last]
          redock_parent_above(points, link, source, target)
          route = generalization_tree_route(points, link, connector, source, target, ends)
          points = route || level_entry_route(points, link, connector, source, target)
          drop_zero_length_tree_segments(points, link)
        end

        def generalization_tree_route(points, link, connector, source, target, ends)
          stored_lateral_route(link, connector, source, target, ported: ends.values.all? { |_, offset| ported?(offset) }) ||
            derived_lateral_route(link, connector, source, target) ||
            horizontal_tree_route(points, link, connector, source, target)
        end

        def end_point(box, kind, offset, edge)
          ported?(offset) ? port(box, offset) : element_edge_point(box, kind, edge)
        end

        # EA's SX/SY (EX/EY) point from the box center toward the port,
        # y up; the port is where that ray leaves the box.
        def port(bounds, offset)
          dx = offset[0].to_f
          dy = -offset[1].to_f
          center_x = bounds.x + bounds.width / 2.0
          center_y = bounds.y + bounds.height / 2.0
          t = [ray_scale(dx, bounds.x, bounds.width, center_x),
               ray_scale(dy, bounds.y, bounds.height, center_y)].min
          [(center_x + t * dx).round, (center_y + t * dy).round]
        end

        def ray_scale(delta, origin, length, center)
          return Float::INFINITY if delta.zero?

          ((delta.positive? ? origin + length : origin) - center) / delta
        end
      end
    end
  end
end
