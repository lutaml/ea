# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Internal geometry for choosing the facing edges of stored routes.
        module Routing
          private

          # Offsets stay attached to semantic Start/End IDs even when the
          # saved corner follows the opposite placement order. Clip each leg
          # from its stored mathematical origin, retaining external origins.
          def reversed_stored_corner(model, link_row, diagram_row, geom, context)
            return model if context || !geom.values_at(:sx, :sy, :ex, :ey).all?

            connector = database.find_connector(link_row.connectorid)
            return model unless connector && reversed_corner_link?(link_row, diagram_row, connector)

            boxes = stored_ray_boxes(link_row, diagram_row)
            origins = [stored_ray_origin(boxes[0], geom[:sx], geom[:sy]),
                       stored_ray_origin(boxes[1], geom[:ex], geom[:ey])]
            x, y = intermediate_waypoints(link_row).first
            bend = Ea::Model::Point.new(x: x, y: y)
            ends = origins.zip(boxes).map do |origin, box|
              inside_box?(origin, box) ? diagonal_corner_exit(origin, bend, box) : origin
            end
            return model unless ends.all?

            model.waypoints = [ends[0], bend, ends[1]].map { |point| Ea::Model::Waypoint.new(position: point) }
            model.source_anchor, model.target_anchor = origins
            model
          end

          # Path follows SOID/EOID placement order, independently of the
          # relationship's Start/End IDs. Only a complete, unique DUID pair
          # can reverse the authored single-corner route.
          def reversed_corner_link?(link_row, diagram_row, connector)
            style = DiagramStyleParser.parse(link_row.style)
            return false unless connector.connector_type == "Association" &&
                                style.values_at(:mode, :lwidth, :tree) == ["3", "0", nil] &&
                                parse_geometry_fields(link_row.geometry)[:edge] == 2 &&
                                intermediate_waypoints(link_row).size == 1

            ids = style.values_at(:soid, :eoid)
            return false if ids.any? { |id| id.to_s.empty? } || ids.uniq.size != 2

            placements = database.diagram_objects_for(diagram_row.diagram_id) || []
            ends = ids.map do |id|
              matches = placements.select { |row| DiagramStyleParser.parse(row.objectstyle)[:duid] == id }
              matches.first.ea_object_id if matches.size == 1
            end
            ends == [connector.end_object_id, connector.start_object_id] && ends.uniq.size == 2
          end

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

          def mark_default_square_ray(model, link_row, geom, context)
            style = model.style.to_h
            return model if context || !link_row.path.to_s.empty? || model.waypoints.size != 2
            return model unless style[:mode] == "3" && style[:tree] == "OS" && style[:lwidth] == "2"
            return model unless geom[:sx].nil? && geom[:sy].nil? && [geom[:ex], geom[:ey]] == [0, 0]

            model.style = style.merge(default_square_ray: true)
            model
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
            allowed = if normalized_port_anchors?(model)
                        normalized_level_ray?(model, source, target, geom)
                      else
                        stored_ray_gap?(source, target, model.style[:mode], geom[:edge])
                      end
            return model unless allowed && stored_association_path?(model, link_row, source, target, geom)

            set_stored_ray_origins(model, source, target, geom)
            model.style[:association_ray_outline] = true if model.connector_type == "Association"
            model
          end

          # An empty-Path Mode 3 Association follows the line between its
          # stored endpoint origins; an omitted offset defaults to the center.
          # The target origin must lie inside its own stroked outline.
          def association_stored_ray(model, link_row, diagram_row, geom, context)
            return model if context
            return stored_diagonal_corner(model, link_row, diagram_row, geom) unless link_row.path.to_s.empty?
            return model unless association_ray_candidate?(model, link_row)

            source, target = stored_ray_boxes(link_row, diagram_row)
            width = association_outline_width(model, link_row, diagram_row)
            origins = association_ray_origins(source, target, geom, width)
            return model unless origins

            model.waypoints = port_waypoints(model, origins)
            model.source_anchor, model.target_anchor = origins
            model.style = model.style.to_h.merge(stored_association_ray: true, association_ray_outline: true)
            if geom[:edge] == 1 && !inside_box?(origins.first, grown_bounds(source, width == "2" ? 1 : 0))
              model.style[:stored_top_dock] = true
            end
            model
          end

          # A single authored bend joins the stored mathematical origins.
          # Clip each leg independently; a facing-edge shortcut loses the bend.
          def stored_diagonal_corner(model, link_row, diagram_row, geom)
            return model unless model.connector_type == "Association" && association_ray_style?(model.style.to_h) &&
                                model.style[:lwidth] == "2" && geom.values_at(:sx, :sy, :ex, :ey).all?

            corners = intermediate_waypoints(link_row)
            return model unless corners.size == 1

            boxes = stored_ray_boxes(link_row, diagram_row)
            origins = [stored_ray_origin(boxes[0], geom[:sx], geom[:sy]),
                       stored_ray_origin(boxes[1], geom[:ex], geom[:ey])]
            bend = Ea::Model::Point.new(x: corners[0][0], y: corners[0][1])
            left, right = boxes.sort_by(&:x)
            return model unless bend.x.between?(left.x + left.width + 1, right.x - 1) &&
                                boxes.all? { |box| bend.y.between?(box.y, box.y + box.height) }

            outlines = boxes.map { |box| grown_bounds(box, 1) }
            return model unless origins.zip(outlines).all? { |origin, box| inside_box?(origin, box) }
            return model if outlines.any? { |box| inside_box?(bend, box) }
            return model unless origins.all? { |origin| origin.x != bend.x && origin.y != bend.y }

            ends = origins.zip(outlines).map { |origin, box| diagonal_corner_exit(origin, bend, box) }
            return model unless ends.all?

            model.waypoints = [ends[0], bend, ends[1]].map { |point| Ea::Model::Waypoint.new(position: point) }
            model.source_anchor, model.target_anchor = origins
            model
          end

          def diagonal_corner_exit(origin, bend, box)
            dx = bend.x - origin.x
            dy = bend.y - origin.y
            times = [(dx.positive? ? box.x + box.width - origin.x : box.x - origin.x).to_f / dx,
                     (dy.positive? ? box.y + box.height - origin.y : box.y - origin.y).to_f / dy]
            time = times.select { |value| value.between?(0, 1) }.min
            return unless time

            Ea::Model::Point.new(x: (origin.x + time * dx).floor, y: (origin.y + time * dy).floor)
          end

          def port_waypoints(model, origins)
            [model.source_port || origins.first, model.target_port || origins.last].map do |point|
              Ea::Model::Waypoint.new(position: point)
            end
          end

          # Width-2 boxes also own their 1px outer stroke, so a stored
          # origin on that outline is still inside its box.
          def association_ray_origins(source, target, geom, width)
            outline = width == "2" ? 1 : 0
            origins = [stored_ray_origin(source, geom[:sx], geom[:sy]),
                       stored_ray_origin(target, geom[:ex], geom[:ey])]
            boxes = [source, target].map { |box| grown_bounds(box, outline) }
            return unless origins.first != origins.last && association_origin_pair?(origins, boxes, width, geom[:edge])

            origins if width == "2" || sub_pixel_safe_origins?(origins, [source, target] + boxes)
          end

          # An external source origin is a virtual point on the saved ray.
          # It is usable only when that segment actually crosses the source.
          def association_origin_pair?(origins, boxes, width, edge)
            return false unless inside_box?(origins.last, boxes.last)
            return true if inside_box?(origins.first, boxes.first)

            return segment_crosses_box?(origins.first, origins.last, boxes.first) if width == "2"
            return false unless edge == 1

            source = boxes.first
            top = Ea::Model::Bounds.new(x: source.x, y: source.y, width: source.width, height: 0)
            segment_crosses_box?(origins.first, origins.last, top)
          end

          def segment_crosses_box?(first, last, box)
            interval = [0.0, 1.0]
            axes = [[first.x, last.x, box.x, box.x + box.width],
                    [first.y, last.y, box.y, box.y + box.height]]
            axes.all? do |origin, finish, low, high|
              if origin == finish
                origin.between?(low, high)
              else
                times = [(low - origin).to_f / (finish - origin),
                         (high - origin).to_f / (finish - origin)].minmax
                interval = [[interval.first, times.first].max, [interval.last, times.last].min]
                interval.first <= interval.last
              end
            end
          end

          def grown_bounds(bounds, amount)
            Ea::Model::Bounds.new(x: bounds.x - amount, y: bounds.y - amount,
                                  width: bounds.width + 2 * amount,
                                  height: bounds.height + 2 * amount)
          end

          def association_ray_candidate?(model, link_row)
            model.connector_type == "Association" && link_row.path.to_s.empty? &&
              model.source_anchor && model.target_anchor &&
              (model.source_port || model.target_port || aligned_default_origins?(model)) &&
              association_ray_style?(model.style.to_h)
          end

          # Zero offsets omit ports, but an explicitly stored axis-aligned
          # width-2 ray still uses the logical centers and stroked outlines.
          def aligned_default_origins?(model)
            model.has_geometry_offsets && model.style[:lwidth] == "2" &&
              (model.source_anchor.x == model.target_anchor.x || model.source_anchor.y == model.target_anchor.y)
          end

          # A thin connector still meets the outer stroke of explicitly
          # bordered elements. Ambiguous placements must agree on that border.
          def association_outline_width(model, link_row, diagram_row)
            width = model.style[:lwidth]
            return width if width == "2"

            connector = database.find_connector(link_row.connectorid)
            ids = [connector.start_object_id, connector.end_object_id]
            placements = database.diagram_objects_for(diagram_row.diagram_id)
            borders = placements.select { |placement| ids.include?(placement.ea_object_id) }
            borders.all? { |placement| DiagramStyleParser.parse(placement.objectstyle)[:lwth] == "2" } ? "2" : width
          end

          def association_ray_style?(style)
            style[:mode] == "3" && !style[:tree] && %w[0 2].include?(style[:lwidth]) &&
              %i[direct regenerated].none? { |key| style.key?(key) }
          end

          # Width-0 origins are whole pixels while EA's box centers may sit
          # on a half pixel. An origin on its border then clips differently
          # unless the line is axis-aligned, which no rounding changes.
          def sub_pixel_safe_origins?(origins, boxes)
            first, last = origins
            axis_aligned = first.x == last.x || first.y == last.y
            axis_aligned || origins.none? { |point| boxes.any? { |box| on_border?(point, box) } }
          end

          def on_border?(point, bounds)
            [bounds.x, bounds.x + bounds.width].include?(point.x) ||
              [bounds.y, bounds.y + bounds.height].include?(point.y)
          end

          def inside_box?(point, bounds)
            point.x.between?(bounds.x, bounds.x + bounds.width) &&
              point.y.between?(bounds.y, bounds.y + bounds.height)
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
            stored_ray_type?(model) &&
              model.waypoints.size == 2 && stored_ray_style?(model.style, link_row) &&
              stored_ray_geometry?(model, geom)
          end

          def stored_ray_type?(model)
            %w[Generalization Aggregation].include?(model.connector_type) ||
              (model.connector_type == "Association" && model.style[:mode] == "1" &&
                model.style[:lwidth] == "2")
          end

          # Boundary-port rounding can move a computed jog off a level saved
          # ray. Equal stored origin rows specify the line before clipping.
          def normalized_level_ray?(model, source, target, geom)
            style = model.style.to_h
            return false unless style[:mode] == "3" && style[:lwidth] == "2" &&
                                horizontal_ray_gap?(source, target)

            origins = [stored_ray_origin(source, geom[:sx], geom[:sy]),
                       stored_ray_origin(target, geom[:ex], geom[:ey])]
            boxes = [source, target].map { |box| grown_bounds(box, 1) }
            origins.first.y == origins.last.y &&
              origins.zip(boxes).all? { |origin, box| inside_box?(origin, box) }
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

              redock_child_below(points, bounds_from_rect(source_placement), bounds_from_rect(target_placement))
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

          # One stored corner that is level with both boxes already is the
          # route (vertical leg out of the source, horizontal leg into the
          # target); flattening it to the facing edges would lose it.
          def level_corner_route?(points, link_row, connector, src, tgt)
            points.size == 3 && level_entry_style?(link_row, connector) &&
              !level_entry_point(points[1], src).nil? && !level_entry_point(points[1], tgt).nil?
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

          # A width-2 Mode 3 route without a tree style keeps authored orthogonal
          # bends: two corners for Associations, two or more for Aggregations.
          # Each end docks on
          # the 1px outline its adjacent leg points at, from the corner's own
          # coordinate; any end that cannot do so leaves the route unchanged.
          def stored_stair_route(link_row, connector, source, target)
            return nil unless stair_style?(link_row, connector)

            corners = stored_square_corners(link_row)
            unless corners && stair_corner_count?(corners, connector.connector_type) && alternating_legs?(corners)
              return nil
            end

            first = outline_dock(corners[0], corners[1], source)
            last = outline_dock(corners[-1], corners[-2], target)
            return nil unless first && last && first != corners.first && last != corners.last

            [first, *corners, last]
          end

          def stair_style?(link_row, connector)
            style = DiagramStyleParser.parse(link_row.style)
            %w[Aggregation Association].include?(connector.connector_type) && style[:mode] == "3" &&
              style[:lwidth] == "2" && !style.key?(:tree)
          end

          def stair_corner_count?(corners, connector_type)
            connector_type == "Association" ? corners.size == 2 : corners.size >= 2
          end

          # Every leg is non-zero and runs along the opposite axis of the last.
          def alternating_legs?(corners)
            axes = corners.each_cons(2).map { |from, to| leg_axis(from, to) }
            axes.none?(&:nil?) && axes.each_cons(2).all? { |a, b| a != b }
          end

          def leg_axis(from, to)
            return :vertical if from[0] == to[0] && from[1] != to[1]

            :horizontal if from[1] == to[1] && from[0] != to[0]
          end

          # The dock runs perpendicular to the corner's own leg.
          def outline_dock(corner, neighbour, box)
            if corner[1] == neighbour[1]
              vertical_outline_dock(corner, box)
            else
              horizontal_outline_dock(corner, box)
            end
          end

          def vertical_outline_dock(corner, box)
            x, y = corner
            return nil unless x.between?(box.x, box.x + box.width) && !within_height?(y, box)

            [x, y < box.y ? box.y - 1 : box.y + box.height + 1]
          end

          def horizontal_outline_dock(corner, box)
            x, y = corner
            return nil unless within_height?(y, box) && !x.between?(box.x, box.x + box.width)

            [x < box.x ? box.x - 1 : box.x + box.width + 1, y]
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

          # A horizontal lateral tree with no usable stored corner leaves
          # the source's top or bottom edge at its center x, turns at the
          # target's center y and enters the target's facing side edge.
          # When that y lies inside the source's height the route is one
          # horizontal line between the facing side edges. Every dock is
          # flush on its box edge.
          def derived_lateral_route(link_row, connector, source, target)
            style = DiagramStyleParser.parse(link_row.style)
            return derived_vertical_lateral_route(style, link_row, connector, source, target) if style[:tree] == "LV"

            return nil unless style[:mode] == "3" && style[:tree] == "LH" &&
                              derived_lateral_path?(connector.connector_type, link_row.path.to_s)

            x = source.x + source.width / 2
            y = target.y + target.height / 2
            edge = lateral_target_edge(x, target)
            return nil unless edge

            if within_height?(y, source)
              side = target.x > x ? source.x + source.width : source.x
              [[side, y], [edge, y]] if ((edge - side) * (edge - x)).positive?
            else
              [[x, y < source.y ? source.y : source.y + source.height], [x, y], [edge, y]]
            end
          end

          # An Association may carry one stored corner that no valid lateral
          # route accepted; a Generalization derives only from an empty Path.
          def derived_lateral_path?(connector_type, path)
            case connector_type
            when "Association" then path.match?(/\A(?:-?\d+:-?\d+;?)?\z/)
            when "Generalization" then path.empty?
            else false
            end
          end

          # A derived level line docks flush at its own two ends; anchoring
          # the ray there keeps the emitter's clip from moving them.
          def pin_derived_lateral_line(model, link_row, diagram_row, context)
            style = model.style.to_h
            return model if context || model.waypoints.size != 2 ||
                            style[:mode] != "3" || style[:tree] != "LH"

            source, target = stored_ray_boxes(link_row, diagram_row)
            connector = database.find_connector(link_row.connectorid)
            line = connector && derived_lateral_route(link_row, connector, source, target)
            return model unless line && line.size == 2 &&
                                line == model.waypoints.map { |wp| [wp.position.x, wp.position.y] }

            model.source_anchor, model.target_anchor = line.map { |x, y| Ea::Model::Point.new(x: x, y: y) }
            model.style = style.merge(derived_lateral_line: true)
            model
          end

          # The target side edge a vertical leg at x faces, or nil when x
          # lies within the target's span.
          def lateral_target_edge(x_position, target)
            return target.x if x_position < target.x

            target.x + target.width if x_position > target.x + target.width
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
            return false unless points.size == 4 && stored_tree_type?(points, link_row, connector, src, tgt)

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

          # A two-waypoint Mode 3 Aggregation with only a target port draws the
          # line from the source center to the target's stored ray origin
          # (center + EX, center - EY), clipped at the outlines; the boundary
          # port is only the derived crossing of that origin's ray.
          def correct_partial_port_origins(model, link_row, diagram_row, geom, context)
            return model if context || !partial_port_origin_candidate?(model, link_row)

            source, target = stored_ray_boxes(link_row, diagram_row)
            return model unless horizontal_ray_gap?(source, target)

            model.source_anchor = stored_ray_origin(source, 0, 0)
            model.target_anchor = stored_ray_origin(target, geom[:ex], geom[:ey])
            model
          end

          def partial_port_origin_candidate?(model, link_row)
            style = model.style.to_h
            model.connector_type == "Aggregation" && model.waypoints.size == 2 &&
              link_row.path.to_s.empty? && style[:mode] == "3" && style[:lwidth] == "2" &&
              !style.key?(:tree) &&
              model.source_port.nil? && model.target_port
          end

          def partial_port_jog_candidate?(model, link_row)
            style = model.style.to_h
            model.connector_type == "Aggregation" &&
              link_row.path.to_s.empty? && style[:mode] == "3" &&
              !style.key?(:tree) && model.waypoints.size == 2 &&
              explicit_port_side?(model, style[:lwidth])
          end

          # Width 2 keeps the evidenced target-only port; width 0 accepts a
          # single explicit port at either end.
          def explicit_port_side?(model, width)
            ports = [model.source_port, model.target_port]
            return model.source_port.nil? && !model.target_port.nil? if width == "2"

            width == "0" && ports.compact.size == 1
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

          def stored_tree_type?(points, link_row, connector, source, target)
            return true if connector.connector_type == "Aggregation"
            return false unless connector.connector_type == "Association" && flush_width_zero_tree?(link_row)

            # Distinct thin bends are supported when the source sits above
            # the target; the established reverse case keeps straight trunks.
            points[1] == points[-2] || source.y + source.height < target.y
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
