# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Routes an XMI connector the way the QEA source does: the same
      # center-ray ports and the same QEA route helpers, over the same
      # inputs (link style, bends in `x:y;` form, connector type, endpoint
      # boxes). Returns nil where QEA would fall back to bare SX/SY deltas,
      # which the generic router keeps handling.
      class StoredRoute < Qea::DiagramBuilder
        Link = Struct.new(:style, :path, :geometry)
        Connector = Struct.new(:connector_type)

        def initialize
          super(nil)
        end

        def waypoints(link:, connector_type:, source:, target:, bends:, offsets:, edge: nil)
          connector = Connector.new(connector_type)
          ports = { source: port_for(source, offsets[:source]), target: port_for(target, offsets[:target]) }
          edge ||= 0
          points = initial_points(link, connector, source, target, bends, ports, edge)
          return unless points

          finish(points, link, connector, source, target, bends, ports, offsets, edge)
        end

        # Direct custom-line associations and aggregations retain ray origins as
        # well as their computed boundary ports, just as the QEA builder does.
        def ray_metadata(model, link:, bounds:, offsets:, edge:)
          return {} unless direct_association_ray?(model, bounds, offsets)

          source, target = bounds.values_at(:source, :target)
          geom = ray_geometry(offsets, edge)
          return {} unless saved_association_ray?(model, link, source, target, geom)

          ray_points(source, target, offsets, geom)
        end

        def phantom_waypoints(source, target)
          [bounds_edge_point(source, target), bounds_edge_point(target, source)]
        end

        private

        def direct_association_ray?(model, bounds, offsets)
          %w[Association Aggregation].include?(model.connector_type) && model.waypoints.size == 2 &&
            model.style.to_h.values_at(:mode, :lwidth, :tree) == ["1", "2", nil] &&
            bounds.values.all? && offsets.values.flatten.none?(&:nil?)
        end

        def ray_geometry(offsets, edge)
          { sx: offsets[:source][0], sy: offsets[:source][1],
            ex: offsets[:target][0], ey: offsets[:target][1], edge: edge }
        end

        def saved_association_ray?(model, link, source, target, geom)
          (!geom[:sy].zero? || !geom[:ey].zero?) &&
            stored_ray_gap?(source, target, "1", geom[:edge]) &&
            stored_association_path?(model, link, source, target, geom)
        end

        def ray_points(source, target, offsets, geom)
          ports = [port_for(source, offsets[:source]), port_for(target, offsets[:target])]
          return {} unless ports.all?

          { source_port: point_for(ports.first), target_port: point_for(ports.last),
            source_anchor: stored_ray_origin(source, geom[:sx], geom[:sy]),
            target_anchor: stored_ray_origin(target, geom[:ex], geom[:ey]),
            has_geometry_offsets: true }
        end

        def point_for(pair)
          Ea::Model::Point.new(x: pair[0], y: pair[1])
        end

        # Placements here are already Ea::Model::Bounds.
        def bounds_from_rect(bounds)
          bounds
        end

        def ported?(offset)
          offset.none?(&:nil?) && offset.any?(&:nonzero?)
        end

        def port_for(box, offset)
          ray_port(box, offset) if ported?(offset)
        end

        def initial_points(link, connector, source, target, bends, ports, edge)
          src = ports[:source] || element_edge_point(source, :source, edge)
          tgt = ports[:target] || element_edge_point(target, :target, edge)
          if Qea::DiagramStyleParser.parse(link.style)[:mode] == "1"
            [src, tgt]
          elsif edge == 2 && ports.values.all? && !valid_tree_path?(bends, source)
            [src, [tgt[0], src[1]], tgt]
          elsif edge == 2 && bends.size == 1
            tree_points(source, target, bends.first)
          elsif bends.any?
            bent_points(src, bends, tgt, link, connector, source, target)
          elsif ports.values.any?
            [src, tgt]
          end
        end

        def tree_points(src, tgt, bend)
          target_y = tgt.y + tgt.height <= src.y ? tgt.y + tgt.height : tgt.y
          [[src.x + src.width, bend[1]], [bend[0], bend[1]], [bend[0], target_y]]
        end

        def bent_points(src, bends, tgt, link, connector, source, target)
          points = [src, *bends, tgt]
          if connector.connector_type == "Generalization"
            preserve_side_entry = authored_lateral_side_entry?(points, bends, link, source, target)
            redock_parent_above(points, link, source, target)
            points[-1] = [points[-1][0], points[1][1]] if preserve_side_entry
          end
          points
        end

        # A single LH tree bend can be the authored side-entry level itself.
        # Parent-above redocking normally moves a Generalization to the target
        # bottom, which destroys that horizontal leg and disagrees with QEA.
        def authored_lateral_side_entry?(points, bends, link, source, target)
          return false unless bends.one? && points.size == 3 && lateral_side_entry_style?(link) &&
                              target.y + target.height <= source.y

          level_on_target_side?(points[1], target)
        end

        def lateral_side_entry_style?(link)
          style = Qea::DiagramStyleParser.parse(link.style)
          style[:mode] == "3" && style[:tree] == "LH" && style[:lwidth] == "2"
        end

        def within_width?(x, bounds)
          x.between?(bounds.x, bounds.x + bounds.width)
        end

        def level_on_target_side?(bend, target)
          bend[1].between?(target.y, target.y + target.height) && !within_width?(bend[0], target)
        end

        def finish(points, link, connector, source, target, bends, ports, offsets, edge)
          tree_route = stored_tree_route(points, link, connector, source, target, ports)
          if tree_route
            points = tree_route
          elsif %w[Association Aggregation].include?(connector.connector_type) && edge != 2
            points = facing(points, link, connector, source, target, bends)
          end
          points = level_entry_route(points, link, connector, source, target) if bends.any? && !tree_route
          points = drop_zero_length_tree_segments(points, link)
          empty_path_ray(points, link, connector, source, target, bends, ports, offsets, edge)
        end

        # An empty Path has no authored corner to keep: a computed EDGE2 jog
        # between ports that face across a gap becomes the straight port line.
        def empty_path_ray(points, link, connector, source, target, bends, ports, offsets, edge)
          style = Qea::DiagramStyleParser.parse(link.style)
          return points unless %w[Generalization Aggregation].include?(connector.connector_type) &&
                               points.size == 3 && bends.empty? && edge == 2 && ports.values.all? &&
                               style[:mode] == "3" && style[:lwidth] == "2" && !style[:tree]
          return points unless ray_gap?(source, target, offsets)

          ports.values_at(:source, :target)
        end

        def ray_gap?(source, target, offsets)
          return false unless source.x + source.width < target.x

          [[source, offsets[:source]], [target, offsets[:target]]].all? do |box, (x, y)|
            within_height?(stored_ray_origin(box, x, y).y, source) &&
              within_height?(stored_ray_origin(box, x, y).y, target)
          end
        end

        def stored_tree_route(points, link, connector, source, target, ports)
          stored_square_route(link, connector, source, target) ||
            stored_stair_route(link, connector, source, target) ||
            stored_lateral_route(link, connector, source, target, ported: ports.values.all?) ||
            derived_lateral_route(link, connector, source, target) ||
            horizontal_tree_route(points, link, connector, source, target)
        end

        def facing(points, link, connector, source, target, bends)
          stored_tree = preserve_stored_tree?(points, link, connector, source, target)
          unless stored_tree || level_corner_route?(points, link, connector, source, target)
            points = facing_edge_route(points, source, target)
          end
          if connector.connector_type == "Aggregation" && bends.any? && points.size >= 4 &&
             (generalization_outline_offset(link, points.size) == 1 ||
              (stored_tree && flush_width_zero_tree?(link)))
            redock_parent_above(points, link, source, target, strict: true)
          end
          redock_vertical_tree_trunk(points, link, connector, source, target) if bends.any?
          points
        end

        # EA's SX/SY (EX/EY) point from the box center toward the port,
        # y up; the port is where that ray leaves the box.
        def ray_port(bounds, offset)
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
