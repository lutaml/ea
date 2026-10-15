# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Internal geometry for choosing the facing edges of stored routes.
        module Routing
          private

          # An empty custom-line Path has no authored corner to preserve.
          # Keep normalized port routes; replace only the computed EDGE2 jog.
          def direct_empty_path_ray(model, link_row, diagram_row, geom, context)
            return model if context
            return model unless empty_path_ray_candidate?(model, link_row, geom)

            source, target = stored_ray_boxes(link_row, diagram_row)
            return model unless empty_path_ray_gap?(source, target, geom)

            model.waypoints = [model.source_port, model.target_port].map do |point|
              Ea::Model::Waypoint.new(position: point)
            end
            set_stored_ray_origins(model, source, target, geom)
          end

          # A Mode 2 Generalization whose stored Path is a horizontal jog
          # between vertically separated boxes that overlap in x is EA's
          # auto-route: one vertical ray at the overlap midpoint plus SX.
          # The stored jog is stale; the ray docks on both 1px outlines.
          def mode2_overlap_ray(model, link_row, diagram_row, geom, context)
            return model if context || !mode2_overlap_candidate?(model, link_row, geom)

            source, target = stored_ray_boxes(link_row, diagram_row)
            column = overlap_ray_coordinate(source.x, source.width, target.x, target.width, geom[:sx])
            return model unless column && vertical_separation?(source, target)

            set_overlap_ray(model, column, source, target)
          end

          def set_overlap_ray(model, column, source, target)
            model.waypoints = overlap_ray_ends(column, source, target).map do |x, y|
              Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
            end
            model.source_anchor, model.target_anchor = [source, target].map do |box|
              Ea::Model::Point.new(x: column, y: box.y + box.height / 2)
            end
            model
          end

          def mode2_overlap_candidate?(model, link_row, geom)
            model.connector_type == "Generalization" && model.has_geometry_offsets &&
              mode2_overlap_style?(model.style.to_h, geom) && model.waypoints.size == 4 &&
              horizontal_jog?(intermediate_waypoints(link_row))
          end

          def mode2_overlap_style?(style, geom)
            style[:mode] == "2" && style[:lwidth] == "2" && !style[:tree] && geom[:edge] == 1 && geom[:sx]
          end

          def horizontal_jog?(corners)
            corners.size == 2 && corners[0][1] == corners[1][1]
          end

          def vertical_separation?(source, target)
            source.y + source.height < target.y || target.y + target.height < source.y
          end

          def overlap_ray_ends(column, source, target)
            if target.y + target.height < source.y
              [[column, source.y - 1], [column, target.y + target.height + 1]]
            else
              [[column, source.y + source.height + 1], [column, target.y - 1]]
            end
          end

          def empty_path_ray_gap?(source, target, geom)
            return false unless source.x + source.width < target.x

            [stored_ray_origin(source, geom[:sx], geom[:sy]),
             stored_ray_origin(target, geom[:ex], geom[:ey])].all? do |origin|
              within_height?(origin.y, source) && within_height?(origin.y, target)
            end
          end

          def empty_path_ray_candidate?(model, link_row, geom)
            %w[Generalization Aggregation].include?(model.connector_type) &&
              model.waypoints.size == 3 && empty_path_ray_style?(model.style, link_row, geom) &&
              model.has_geometry_offsets && model.source_port && model.target_port
          end

          def empty_path_ray_style?(style, link_row, geom)
            style[:mode] == "3" && style[:lwidth] == "2" && !style[:tree] &&
              geom[:edge] == 2 && link_row.path.to_s.empty?
          end

          # Stored SY/EY use mathematical Y; ray origins use screen Y.
          # Computed-jog origins are already normalized to their derived ports.
          def correct_stored_ray_origins(model, link_row, diagram_row, geom, context)
            return model if context
            return model unless stored_ray_candidate?(model, link_row, geom)

            source, target = stored_ray_boxes(link_row, diagram_row)
            return model unless stored_ray_gap?(source, target, model.style[:mode], geom[:edge])

            set_stored_ray_origins(model, source, target, geom)
          end

          # An empty-Path Mode 3 Association with explicit offsets on both
          # ends is the straight line between the two stored ray origins.
          # Origins outside their own box are not a stored ray.
          def association_stored_ray(model, link_row, diagram_row, geom, context)
            return model if context
            return model unless association_ray_candidate?(model, link_row)

            source, target = stored_ray_boxes(link_row, diagram_row)
            origins = association_ray_origins(source, target, geom)
            return model unless origins

            model.waypoints = [model.source_port, model.target_port].map do |point|
              Ea::Model::Waypoint.new(position: point)
            end
            model.source_anchor, model.target_anchor = origins
            model
          end

          def association_ray_origins(source, target, geom)
            origins = [stored_ray_origin(source, geom[:sx], geom[:sy]),
                       stored_ray_origin(target, geom[:ex], geom[:ey])]
            inside = origins.zip([source, target]).all? { |o, b| inside_box?(o, b) }
            origins if inside && sub_pixel_safe_origins?(origins, [source, target])
          end

          def association_ray_candidate?(model, link_row)
            model.connector_type == "Association" && link_row.path.to_s.empty? &&
              model.has_geometry_offsets && model.source_port && model.target_port &&
              association_ray_style?(model.style.to_h)
          end

          def association_ray_style?(style)
            style[:mode] == "3" && !style[:tree] && %w[0 2].include?(style[:lwidth]) &&
              %i[direct regenerated].none? { |key| style.key?(key) }
          end

          # Origins are whole pixels while EA's box centers may sit on a
          # half pixel. An origin on its border then clips differently
          # unless the line is axis-aligned, which no rounding changes.
          def sub_pixel_safe_origins?(origins, boxes)
            first, last = origins
            return false if first == last

            axis_aligned = first.x == last.x || first.y == last.y
            axis_aligned || origins.zip(boxes).none? { |point, box| on_border?(point, box) }
          end

          def on_border?(point, bounds)
            [bounds.x, bounds.x + bounds.width].include?(point.x) ||
              [bounds.y, bounds.y + bounds.height].include?(point.y)
          end

          def inside_box?(point, bounds)
            point.x.between?(bounds.x, bounds.x + bounds.width) &&
              point.y.between?(bounds.y, bounds.y + bounds.height)
          end

          # A Mode 2 Association with equal SX/EX (vertical EDGE 1/3) or
          # equal SY/EY (horizontal EDGE 4) and no custom Path docks as a
          # straight line through the middle of the boxes' overlap, moved
          # by the shared stored offset. Stored SY counts upward.
          def overlap_ray_origins(model, link_row, diagram_row, geom, context)
            return model if context
            return model unless overlap_ray_candidate?(model, link_row, geom)

            source, target = stored_ray_boxes(link_row, diagram_row)
            origins = overlap_origins(source, target, geom)
            return model unless origins

            model.source_anchor, model.target_anchor = origins.map do |ox, oy|
              Ea::Model::Point.new(x: ox, y: oy)
            end
            model.style[:overlap_ray] = true
            model
          end

          # Both ray origins share the overlap coordinate on the axis the
          # offsets move and sit at each box's centre on the other axis.
          def overlap_origins(source, target, geom)
            along, across, offset = overlap_axes(geom)
            coordinate = overlap_ray_coordinate(*box_span(source, along), *box_span(target, along), offset)
            return nil unless coordinate && disjoint_span?(*box_span(source, across), *box_span(target, across))

            [source, target].map do |box|
              start, size = box_span(box, across)
              centre = start + size / 2.0
              geom[:edge] == 4 ? [centre, coordinate] : [coordinate, centre]
            end
          end

          # [axis the offsets move, axis the boxes face, stored offset]
          def overlap_axes(geom)
            return [%i[y height], %i[x width], -geom[:sy]] if geom[:edge] == 4

            [%i[x width], %i[y height], geom[:sx]]
          end

          def box_span(box, keys)
            keys.map { |key| box.public_send(key) }
          end

          def overlap_ray_candidate?(model, link_row, geom)
            model.connector_type == "Association" && model.style[:mode] == "2" &&
              model.waypoints.size == 2 && link_row.path.to_s.empty? &&
              model.has_geometry_offsets && uniform_overlap_offsets?(geom)
          end

          def uniform_overlap_offsets?(geom)
            return false unless geom.values_at(:sx, :sy, :ex, :ey).all?

            geom[:edge] == 4 ? geom[:sy] == geom[:ey] : [1, 3].include?(geom[:edge]) && geom[:sx] == geom[:ex]
          end

          # Floor of the overlap midpoint plus the shared offset; nil
          # when the boxes do not overlap on this axis.
          def overlap_ray_coordinate(start_a, size_a, start_b, size_b, offset)
            low = [start_a, start_b].max
            high = [start_a + size_a, start_b + size_b].min
            return nil if low > high

            coordinate = ((low + high) / 2.0 + offset).floor
            coordinate if coordinate.between?(low, high)
          end

          def disjoint_span?(start_a, size_a, start_b, size_b)
            start_a + size_a < start_b || start_b + size_b < start_a
          end

          def stored_ray_boxes(link_row, diagram_row)
            connector = database.find_connector(link_row.connectorid)
            [source_placement_for(connector, diagram_row),
             target_placement_for(connector, diagram_row)].map { |placement| bounds_from_rect(placement) }
          end

          def set_stored_ray_origins(model, source, target, geom)
            model.source_anchor = stored_ray_origin(source, geom[:sx], geom[:sy])
            model.target_anchor = stored_ray_origin(target, geom[:ex], geom[:ey])
            model
          end

          def stored_ray_candidate?(model, link_row, geom)
            %w[Generalization Aggregation].include?(model.connector_type) &&
              model.waypoints.size == 2 && stored_ray_style?(model.style, link_row) &&
              stored_ray_geometry?(model, geom) && !normalized_port_anchors?(model)
          end

          def stored_ray_style?(style, link_row)
            %w[1 3].include?(style[:mode]) && !style[:tree] &&
              (style[:mode] == "1" || link_row.path.to_s.empty?)
          end

          def stored_ray_geometry?(model, geom)
            model.has_geometry_offsets && model.source_port && model.target_port &&
              (!geom[:sy].to_i.zero? || !geom[:ey].to_i.zero?)
          end

          def normalized_port_anchors?(model)
            same_port_anchor?(model.source_anchor, model.source_port) &&
              same_port_anchor?(model.target_anchor, model.target_port)
          end

          def same_port_anchor?(anchor, port)
            anchor.x == port.x && anchor.y == port.y
          end

          def stored_ray_gap?(source, target, mode, edge)
            return horizontal_ray_gap?(source, target) || vertical_ray_gap?(source, target) if mode == "1"

            if edge == 1
              target.y + target.height < source.y
            elsif edge == 4
              target.x + target.width < source.x
            end
          end

          def horizontal_ray_gap?(source, target)
            source.x + source.width < target.x || target.x + target.width < source.x
          end

          def vertical_ray_gap?(source, target)
            source.y + source.height < target.y || target.y + target.height < source.y
          end

          def stored_ray_origin(bounds, x_offset, y_offset)
            Ea::Model::Point.new(x: bounds.x + bounds.width / 2 + x_offset.to_i,
                                 y: bounds.y + bounds.height / 2 - y_offset.to_i)
          end

          # A vertical tree stores its trunk bend twice when the parent sits
          # directly above; EA draws that as one bend.
          def drop_zero_length_tree_segments(points, link_row)
            return points unless points.size == 4 && points[1] == points[2] &&
                                 DiagramStyleParser.parse(link_row.style)[:tree] == "V"

            points.values_at(0, 1, 3)
          end

          # A stored vertical tree trunk docks both ends on the box edges that
          # face its bends, at the adjacent bend's x: Aggregations without
          # geometry offsets whose child sits below, and flush Associations
          # whose parent sits above. Other shapes keep their stored docks.
          def redock_vertical_tree_trunk(points, link_row, connector, source_placement, target_placement)
            style = DiagramStyleParser.parse(link_row.style)
            return unless points.size == 4 && style[:tree] == "V"

            case connector.connector_type
            when "Aggregation"
              return unless style[:lwidth] == "0" || !geometry_has_offsets?(link_row.geometry)

              redock_child_below(points, bounds_from_rect(source_placement), bounds_from_rect(target_placement))
            when "Association"
              return unless style[:lwidth] == "0"

              redock_parent_above(points, link_row, source_placement, target_placement, strict: true)
            end
          end

          def redock_child_below(points, src_b, tgt_b)
            first_bend, last_bend = points.values_at(1, -2)
            source_y = src_b.y + src_b.height
            return points unless source_y <= tgt_b.y && first_bend[1] > source_y && last_bend[1] < tgt_b.y

            points[0] = [clamp_to_span(first_bend[0], src_b), source_y]
            points[-1] = [clamp_to_span(last_bend[0], tgt_b), tgt_b.y]
            points
          end

          def clamp_to_span(position, bounds)
            position.clamp(bounds.x, bounds.x + bounds.width)
          end

          # A stored-Path Mode 3 width-2 end whose adjacent bend lies level
          # with its box (inside the box's span on one axis, outside on the
          # other) enters the box orthogonally on the outer outline at that
          # bend's coordinate. Bends that are not level keep the port and
          # every authored corner stays.
          def level_entry_route(points, link_row, connector, src, tgt)
            return points unless points.size >= 3 && level_entry_style?(link_row, connector)

            route = points.dup
            first = level_entry_point(route[1], src)
            last = level_entry_point(route[-2], tgt)
            route[0] = first if first
            route[-1] = last if last
            route
          end

          def level_entry_style?(link_row, connector)
            style = DiagramStyleParser.parse(link_row.style)
            %w[Generalization Aggregation].include?(connector.connector_type) &&
              style[:mode] == "3" && style[:lwidth] == "2" && !style.key?(:tree)
          end

          def level_entry_point(bend, box)
            level_y = bend[1] > box.y && bend[1] < box.y + box.height
            level_x = bend[0] > box.x && bend[0] < box.x + box.width
            if level_y && outside_span?(bend[0], box.x, box.width)
              [bend[0] < box.x ? box.x - 1 : box.x + box.width + 1, bend[1]]
            elsif level_x && outside_span?(bend[1], box.y, box.height)
              [bend[0], bend[1] < box.y ? box.y - 1 : box.y + box.height + 1]
            end
          end

          def outside_span?(value, start, length)
            value < start || value > start + length
          end

          # Square routing keeps the stored orthogonal trunk, even when a
          # shorter facing-edge route exists between the same boxes.
          def stored_square_route(link_row, connector, source, target)
            return nil unless stored_square_style?(link_row, connector)

            corners = stored_square_corners(link_row)
            square_corner_route(corners, source, target) if corners
          end

          def stored_square_style?(link_row, connector)
            style = DiagramStyleParser.parse(link_row.style)
            %w[Association Aggregation Generalization].include?(connector.connector_type) &&
              style[:mode] == "3" && style[:tree] == "OS" && style[:lwidth] == "2"
          end

          def stored_square_corners(link_row)
            return nil unless link_row.path.to_s.match?(/\A(?:-?\d+:-?\d+;)*-?\d+:-?\d+;?\z/)

            corners = intermediate_waypoints(link_row)
            corners if corners.each_cons(2).all? { |a, b| a[0] == b[0] || a[1] == b[1] }
          end

          def square_corner_route(corners, source, target)
            first = square_corner_dock(corners.first, source)
            last = square_corner_dock(corners.last, target)
            return nil unless first && last

            points = corners.dup
            points.unshift(first) unless points.first == first
            points.push(last) unless points.last == last
            points if points.size >= 3
          end

          def square_corner_dock(corner, bounds)
            x, y = corner
            projected = [x.clamp(bounds.x, bounds.x + bounds.width),
                         y.clamp(bounds.y, bounds.y + bounds.height)]
            return nil if projected[0] != x && projected[1] != y

            projected if rectangle_edge?(projected, bounds)
          end

          def rectangle_edge?(point, bounds)
            [bounds.x, bounds.x + bounds.width].include?(point[0]) ||
              [bounds.y, bounds.y + bounds.height].include?(point[1])
          end

          # A valid lateral corner joins one vertical leg and one horizontal
          # leg. Keep it even when the boxes also admit a shorter direct route.
          # ported: both ends carry explicit SX/SY and EX/EY offsets. An
          # untyped corner without them may be an authored diagonal.
          def stored_lateral_route(link_row, connector, source, target, ported: false)
            return nil unless %w[Aggregation Association].include?(connector.connector_type)

            style = DiagramStyleParser.parse(link_row.style)
            return nil unless stored_lateral_style?(style, connector, ported)

            corner = stored_lateral_corner(link_row)
            corner && lateral_corner_route(style, corner, source, target)
          end

          # An untyped Mode 3 Association corner takes whichever leg
          # orientation its position fits; width-2 docks sit on the 1px
          # outer outline.
          def lateral_corner_route(style, corner, source, target)
            case style[:tree]
            when "LH" then horizontal_corner_route(corner, source, target)
            when "LV" then vertical_corner_route(corner, source, target)
            else
              outline = style[:lwidth] == "2" ? 1 : 0
              horizontal_corner_route(corner, source, target, outline) ||
                vertical_corner_route(corner, source, target, outline)
            end
          end

          def stored_lateral_corner(link_row)
            return nil unless link_row.path.to_s.match?(/\A-?\d+:-?\d+;?\z/)

            intermediate_waypoints(link_row).first
          end

          def stored_lateral_style?(style, connector, ported)
            return false unless style[:mode] == "3" && %w[0 2].include?(style[:lwidth])

            %w[LH LV].include?(style[:tree]) ||
              (style[:tree].nil? && ported && connector.connector_type == "Association")
          end

          def horizontal_corner?(corner, source, target)
            within_horizontal_span?(corner, source) && within_height?(corner[1], target) &&
              !within_height?(corner[1], source) && !within_horizontal_span?(corner, target)
          end

          def horizontal_corner_route(corner, source, target, outline = 0)
            return nil unless horizontal_corner?(corner, source, target)

            x, y = corner

            source_y = y < source.y ? source.y - outline : source.y + source.height + outline
            target_x = x < target.x ? target.x - outline : target.x + target.width + outline
            [[x, source_y], corner, [target_x, y]]
          end

          def vertical_corner?(corner, source, target)
            within_height?(corner[1], source) && within_horizontal_span?(corner, target) &&
              !within_horizontal_span?(corner, source) && !within_height?(corner[1], target)
          end

          def vertical_corner_route(corner, source, target, outline = 0)
            return nil unless vertical_corner?(corner, source, target)

            x, y = corner

            source_x = x < source.x ? source.x - outline : source.x + source.width + outline
            target_y = y < target.y ? target.y - outline : target.y + target.height + outline
            [[source_x, y], corner, [x, target_y]]
          end

          def within_height?(height, bounds)
            height.between?(bounds.y, bounds.y + bounds.height)
          end

          # A lateral tree leaves the side edge before turning upward.
          # Keep that dock only when its first leg actually points outward.
          def lateral_source_exit?(points, link_row, bounds)
            return false unless points.size == 3 && DiagramStyleParser.parse(link_row.style)[:tree] == "LV"

            anchor, bend = points.take(2)
            anchor[1] == bend[1] && outward_side_exit?(anchor[0], bend[0], bounds)
          end

          def outward_side_exit?(anchor_x, bend_x, bounds)
            left = bounds.x
            right = left + bounds.width
            (anchor_x == left && bend_x < left) || (anchor_x == right && bend_x > right)
          end

          # Keep a vertical tree trunk whose bends still fit both boxes
          # and the open gap; the closest facing edges need not share its x.
          def preserve_stored_tree?(points, link_row, connector, src, tgt)
            return false unless points.size == 4 && stored_tree_type?(points, link_row, connector)

            style = DiagramStyleParser.parse(link_row.style)
            return false unless style[:lwidth] == "2" || flush_width_zero_tree?(link_row)
            return false unless vertical_tree_style?(style)

            tree_bends_fit?(points[1], points[-2], src, tgt, flush_width_zero_tree?(link_row))
          end

          # A width-2 Mode 3 horizontal tree keeps its stored vertical trunk
          # and docks both ends on the facing sides' 1px outer outlines at
          # the bend heights. Returns nil unless the trunk sits strictly
          # inside the open gap and each bend lies inside its own box.
          def horizontal_tree_route(points, link_row, connector, src, tgt)
            return nil unless points.size == 4 && horizontal_tree_style?(link_row, connector)

            first, last = points.values_at(1, 2)
            src_x, tgt_x = facing_outline_xs(src, tgt)
            return nil unless src_x && trunk_in_gap?(first, last, src_x, tgt_x)
            return nil unless inside_height?(first[1], src) && inside_height?(last[1], tgt)

            [[src_x, first[1]], first, last, [tgt_x, last[1]]]
          end

          def horizontal_tree_style?(link_row, connector)
            style = DiagramStyleParser.parse(link_row.style)
            %w[Generalization Aggregation].include?(connector.connector_type) &&
              style[:tree] == "H" && style[:lwidth] == "2" && style[:mode] == "3"
          end

          def trunk_in_gap?(first, last, src_x, tgt_x)
            first[0] == last[0] && first[1] != last[1] &&
              first[0] > [src_x, tgt_x].min && first[0] < [src_x, tgt_x].max
          end

          def inside_height?(height, bounds)
            height > bounds.y && height < bounds.y + bounds.height
          end

          # Source and target x on the facing sides' outer outlines, or nil
          # when the boxes are not horizontally separated.
          def facing_outline_xs(src, tgt)
            source_left = src.x
            source_right = source_left + src.width
            target_left = tgt.x
            target_right = target_left + tgt.width
            if target_right < source_left
              [source_left - 1, target_right + 1]
            elsif source_right < target_left
              [source_right + 1, target_left - 1]
            end
          end

          # A computed Mode 3 Generalization between horizontally disjoint
          # boxes whose two explicit ports sit on the facing sides one pixel
          # apart in y or less (edge-port integer rounding) is one horizontal line.
          # Stored Path jogs and every other shape keep their route.
          def collapse_computed_jog(model, link_row, diagram_row, geom)
            return model unless computed_jog_candidate?(model, link_row, geom)

            connection = database.find_connector(link_row.connectorid)
            src, tgt = [connection.start_object_id, connection.end_object_id].map do |id|
              placement = diagram_object_placement(diagram_row.diagram_id, id)
              placement && bounds_from_rect(placement)
            end
            return model unless src && tgt && facing_jog_ports?(model.source_port, model.target_port, src, tgt)

            ends = [[model.source_port.x, model.source_port.y],
                    [model.target_port.x, model.source_port.y]].map do |x, y|
              Ea::Model::Point.new(x: x, y: y)
            end
            model.waypoints = ends.map { |point| Ea::Model::Waypoint.new(position: point) }
            model.source_anchor = model.source_port = ends.first
            model.target_anchor = model.target_port = ends.last
            model
          end

          # Same one-pixel collapse for a two-waypoint computed line when only
          # the target carries an explicit port (the source end is the default
          # edge midpoint): the left-hand end's y wins.
          def collapse_partial_port_jog(model, link_row, diagram_row)
            return model unless partial_port_jog_candidate?(model, link_row)

            connection = database.find_connector(link_row.connectorid)
            src, tgt = [connection.start_object_id, connection.end_object_id].map do |id|
              placement = diagram_object_placement(diagram_row.diagram_id, id)
              placement && bounds_from_rect(placement)
            end
            from, to = model.waypoints.map(&:position)
            return model unless src && tgt && facing_jog_ports?(from, to, src, tgt)

            level = [from, to].min_by(&:x).y
            ends = [[from.x, level], [to.x, level]].map do |x, y|
              Ea::Model::Point.new(x: x, y: y)
            end
            model.waypoints = ends.map { |point| Ea::Model::Waypoint.new(position: point) }
            model.source_anchor = model.source_port = ends.first
            model.target_anchor = model.target_port = ends.last
            model
          end

          def partial_port_jog_candidate?(model, link_row)
            style = model.style.to_h
            model.connector_type == "Aggregation" &&
              link_row.path.to_s.empty? && style[:mode] == "3" && style[:lwidth] == "2" &&
              !style.key?(:tree) && model.source_port.nil? && model.target_port &&
              model.waypoints.size == 2
          end

          def computed_jog_candidate?(model, link_row, geom)
            style = model.style.to_h
            model.connector_type == "Generalization" && geom[:edge] == 2 &&
              link_row.path.to_s.empty? && style[:mode] == "3" && style[:lwidth] == "2" &&
              !style.key?(:tree) && model.source_port && model.target_port &&
              model.waypoints.size == 3
          end

          def facing_jog_ports?(from, to, src, tgt)
            return false unless (from.y - to.y).abs <= 1 && from.y.between?(tgt.y, tgt.y + tgt.height)

            if src.x + src.width < tgt.x
              from.x == src.x + src.width && to.x == tgt.x
            elsif tgt.x + tgt.width < src.x
              from.x == src.x && to.x == tgt.x + tgt.width
            else
              false
            end
          end

          # Width-0 vertical trees dock on the box edges themselves (no outline).
          def flush_width_zero_tree?(link_row)
            style = DiagramStyleParser.parse(link_row.style)
            style[:mode] == "3" && style[:tree] == "V" && style[:lwidth] == "0"
          end

          def vertical_tree_style?(style)
            style[:tree] == "V" || (style[:mode] == "3" && style[:tree].nil?)
          end

          def stored_tree_type?(points, link_row, connector)
            connector.connector_type == "Aggregation" || flush_straight_association?(points, link_row, connector)
          end

          # A flush Association keeps only a straight trunk (one bend stored twice).
          def flush_straight_association?(points, link_row, connector)
            connector.connector_type == "Association" && points[1] == points[-2] &&
              flush_width_zero_tree?(link_row)
          end

          # A flush trunk may also hang below its parent; a bend repeated at
          # one x is a straight trunk with a single bend.
          def tree_bends_fit?(first, last, source, target, flush)
            first[1] == last[1] &&
              within_vertical_gap?(first[1], source, target, flush) &&
              within_horizontal_span?(first, source) && within_horizontal_span?(last, target)
          end

          def within_vertical_gap?(height, source, target, flush)
            return true if height < source.y - 1 && height > target.y + target.height + 1

            flush && height > source.y + source.height + 1 && height < target.y - 1
          end

          def within_horizontal_span?(point, bounds)
            point[0].between?(bounds.x, bounds.x + bounds.width)
          end

          # Returns a replacement 2-point route between the closest
          # facing edges, or the original points when: the boxes overlap
          # on both axes, the current route already docks those edges,
          # or no aligned dock fits the edges' overlap range.
          def facing_edge_route(points, src, tgt)
            v_gap = v_dir = h_gap = h_dir = nil
            if src.y >= tgt.y + tgt.height
              v_gap = src.y - (tgt.y + tgt.height)
              v_dir = [:t, :b]
            elsif tgt.y >= src.y + src.height
              v_gap = tgt.y - (src.y + src.height)
              v_dir = [:b, :t]
            end
            if src.x >= tgt.x + tgt.width
              h_gap = src.x - (tgt.x + tgt.width)
              h_dir = [:l, :r]
            elsif tgt.x >= src.x + src.width
              h_gap = tgt.x - (tgt.x + tgt.width)
              h_dir = [:r, :l]
            end
            return points if v_gap.nil? && h_gap.nil?

            if !v_gap.nil? && (h_gap.nil? || v_gap <= h_gap)
              src_edge, tgt_edge = v_dir
            else
              src_edge, tgt_edge = h_dir
            end
            return points if docks_edges?(points, src, src_edge, tgt, tgt_edge)

            if %i[t b].include?(src_edge)
              lo = [src.x, tgt.x].max
              hi = [src.x + src.width, tgt.x + tgt.width].min
              return points if lo > hi

              x = points.first[0].clamp(lo, hi)
              [[x, src_edge == :t ? src.y : src.y + src.height],
               [x, tgt_edge == :t ? tgt.y : tgt.y + tgt.height]]
            else
              lo = [src.y, tgt.y].max
              hi = [src.y + src.height, tgt.y + tgt.height].min
              return points if lo > hi

              y = points.first[1].clamp(lo, hi)
              [[src_edge == :l ? src.x : src.x + src.width, y],
               [tgt_edge == :l ? tgt.x : tgt.x + tgt.width, y]]
            end
          end

          def docks_edges?(points, src, src_edge, tgt, tgt_edge)
            on_edge?(points.first, src, src_edge) && on_edge?(points.last, tgt, tgt_edge)
          end

          def on_edge?(pt, b, edge, tol = 2)
            x, y = pt
            case edge
            when :l then (x - b.x).abs <= tol && y.between?(b.y - tol, b.y + b.height + tol)
            when :r then (x - (b.x + b.width)).abs <= tol && y.between?(b.y - tol, b.y + b.height + tol)
            when :t then (y - b.y).abs <= tol && x.between?(b.x - tol, b.x + b.width + tol)
            else (y - (b.y + b.height)).abs <= tol && x.between?(b.x - tol, b.x + b.width + tol)
            end
          end
        end
      end
    end
  end
end
