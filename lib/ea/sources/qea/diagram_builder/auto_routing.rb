# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Stored mathematical docking for auto-routed associations.
        module AutoRouting
          private

          # Without an authored Path, a direct Association can still store
          # aligned mathematical origins rather than screen-space ports.
          def stored_association_path?(model, link_row, source, target, geom)
            return true unless model.connector_type == "Association" && link_row.path.to_s.empty?
            return false unless geom.values_at(:sx, :sy, :ex, :ey).all?

            origins = [stored_ray_origin(source, geom[:sx], geom[:sy]),
                       stored_ray_origin(target, geom[:ex], geom[:ey])]
            origins.first.y == origins.last.y && horizontal_ray_gap?(source, target) &&
              origins.zip([source, target]).all? { |origin, box| inside_box?(origin, grown_bounds(box, 1)) }
          end

          # A Mode 2 Association with equal SX/EX (vertical EDGE 1/3) or
          # equal SY/EY (horizontal EDGE 2/4) and no custom Path docks as a
          # straight line through the middle of the boxes' overlap, moved
          # by the shared stored offset. Stored SY counts upward.
          def overlap_ray_origins(model, link_row, diagram_row, geom, context)
            return model if context
            return model unless overlap_ray_candidate?(model, link_row, geom)

            source, target = stored_ray_boxes(link_row, diagram_row)
            origins = overlap_origins(source, target, geom)
            return model unless origins && overlap_correction?(source, target, geom)

            model.source_anchor, model.target_anchor = origins.map do |ox, oy|
              Ea::Model::Point.new(x: ox, y: oy)
            end
            if model.waypoints.size == 3
              model.waypoints = port_waypoints(model, [model.source_anchor, model.target_anchor])
            end
            model.style[:overlap_ray] = true
            model
          end

          # Aligned, zero-offset EDGE 2 routes already have their legacy docks.
          def overlap_correction?(source, target, geom)
            geom[:edge] != 2 || !geom[:sy].zero? ||
              source.y * 2 + source.height != target.y * 2 + target.height
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
              [2, 4].include?(geom[:edge]) ? [centre, coordinate] : [coordinate, centre]
            end
          end

          # [axis the offsets move, axis the boxes face, stored offset]
          def overlap_axes(geom)
            return [%i[y height], %i[x width], -geom[:sy]] if [2, 4].include?(geom[:edge])

            [%i[x width], %i[y height], geom[:sx]]
          end

          def box_span(box, keys)
            keys.map { |key| box.public_send(key) }
          end

          def overlap_ray_candidate?(model, link_row, geom)
            model.connector_type == "Association" && model.style[:mode] == "2" &&
              [2, 3].include?(model.waypoints.size) && link_row.path.to_s.empty? && !model.style[:tree] &&
              model.has_geometry_offsets && uniform_overlap_offsets?(geom)
          end

          def uniform_overlap_offsets?(geom)
            return false unless geom.values_at(:sx, :sy, :ex, :ey).all?

            if [2, 4].include?(geom[:edge])
              geom[:sy] == geom[:ey]
            else
              [1, 3].include?(geom[:edge]) && geom[:sx] == geom[:ex]
            end
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

          # Nonuniform horizontal offsets move the shared overlap row by SY.
          # Uniform offsets retain the shared-overlap routing contract.
          def source_row_association_ray(model, link_row, diagram_row, geom, context)
            return model if context || !source_row_association?(model, geom)

            source, target = stored_ray_boxes(link_row, diagram_row)
            return model unless source_row_path?(link_row, source, target)

            origins = source_row_origins(source, target, geom)
            return model unless origins

            model.source_anchor, model.target_anchor = origins
            model.waypoints = origins.map { |point| Ea::Model::Waypoint.new(position: point) }
            model.style[:overlap_ray] = true
            model
          end

          # When the shared row misses the target, retain the physical ports
          # and let the emitter clip their ray before inserting the elbow.
          def auto_port_elbow(model, link_row, diagram_row, geom, context)
            return model if context || !auto_port_elbow_candidate?(model, link_row, geom)

            source, target = stored_ray_boxes(link_row, diagram_row)
            origins = [stored_ray_origin(source, geom[:sx], geom[:sy]),
                       stored_ray_origin(target, geom[:ex], geom[:ey])]
            return model unless auto_port_elbow_origins?(source, target, origins, geom)

            apply_auto_port_elbow(model, origins)
          end

          def apply_auto_port_elbow(model, origins)
            model.source_anchor, model.target_anchor = origins
            model.waypoints = origins.map { |point| Ea::Model::Waypoint.new(position: point) }
            model.style = model.style.to_h.merge(association_ray_outline: true, auto_port_elbow: true)
            model
          end

          def auto_port_elbow_candidate?(model, link_row, geom)
            auto_port_elbow_model?(model) && link_row.path.to_s.empty? &&
              source_row_style?(model.style.to_h) && uniform_overlap_offsets?(geom) && geom[:edge] == 4
          end

          def auto_port_elbow_model?(model)
            model.connector_type == "Association" && model.has_geometry_offsets &&
              model.source_anchor && model.target_anchor && model.waypoints.size == 2
          end

          def auto_port_elbow_origins?(source, target, origins, geom)
            return false if overlap_origins(source, target, geom)
            return false unless source_row_faces_target?(source, target, geom[:edge])
            return false unless origins.first.x == source.x - 1
            return false if within_height?(origins.first.y, target)
            return false unless crosses_target_horizontal_edge?(origins, target)

            [source, target].zip(origins).all? { |box, origin| inside_box?(origin, grown_bounds(box, 1)) }
          end

          def crosses_target_horizontal_edge?(origins, target)
            outline = grown_bounds(target, 1)
            edge = Ea::Model::Bounds.new(x: outline.x, width: outline.width, height: 0,
                                         y: origins.first.y < outline.y ? outline.y : outline.y + outline.height)
            segment_crosses_box?(*origins, edge)
          end

          def source_row_origins(source, target, geom)
            return nil unless source_row_faces_target?(source, target, geom[:edge])

            row = overlap_ray_coordinate(source.y, source.height, target.y, target.height, -geom[:sy])
            return nil unless row && [source, target].all? { |box| within_height?(row, box) }

            [source, target].map { |box| Ea::Model::Point.new(x: box.x + box.width / 2.0, y: row) }
          end

          def source_row_faces_target?(source, target, edge)
            if edge == 2
              source.x + source.width < target.x
            else
              target.x + target.width < source.x
            end
          end

          def source_row_association?(model, geom)
            model.connector_type == "Association" && model.has_geometry_offsets &&
              model.source_anchor && model.target_anchor &&
              source_row_style?(model.style.to_h) &&
              source_row_offsets?(geom)
          end

          def source_row_path?(link_row, source, target)
            link_row.path.to_s.empty? || stale_horizontal_jog?(link_row, source, target)
          end

          # A horizontal saved jog outside both boxes is stale auto-routing.
          # A corner that still lies beside either box remains authored.
          def stale_horizontal_jog?(link_row, source, target)
            corners = intermediate_waypoints(link_row)
            horizontal_jog?(corners) && [source, target].none? { |box| within_height?(corners.first[1], box) }
          end

          def source_row_style?(style)
            style[:mode] == "2" && style[:lwidth] == "2" && !style[:tree]
          end

          def source_row_offsets?(geom)
            geom.values_at(:sx, :sy, :ex, :ey).all? &&
              [2, 4].include?(geom[:edge]) && geom[:sy] != geom[:ey]
          end
        end
      end
    end
  end
end
