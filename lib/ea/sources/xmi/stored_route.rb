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

        def waypoints(link:, connector_type:, source:, target:, bends:, offsets:)
          connector = Struct.new(:connector_type).new(connector_type)
          stored_square_route(link, connector, source, target) ||
            stored_stair_route(link, connector, source, target) ||
            level_entry(link, connector, source, target, bends, offsets)
        end

        private

        def level_entry(link, connector, source, target, bends, offsets)
          return unless level_entry_style?(link, connector) && bends.any?

          points = [port(source, offsets[:source]), *bends, port(target, offsets[:target])]
          level_entry_route(points, link, connector, source, target)
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
