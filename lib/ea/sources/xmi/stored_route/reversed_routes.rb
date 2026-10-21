# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      class StoredRoute < Qea::DiagramBuilder
        # QEA's reversed-end Association rules for XMI. A connector is reversed
        # when its SOID names a placement other than the relationship's source
        # (builder flag :reversed_ends). Geometry helpers come from
        # Qea::DiagramBuilder::Routing, so both sources share one rule.
        module ReversedRoutes
          private

          # A width-0 vertical-tree Association takes the bus 50px past the End
          # box's facing edge with legs at the stored origins (an empirical fit,
          # see Routing#reversed_tree_route; checked on 5038EEE3).
          def reversed_tree_metadata(model, link, bounds, offsets, edge)
            return {} unless reversed_tree_candidate?(model, link, bounds, offsets)

            start, finish = bounds.values_at(:source, :target)
            bus, start_edge, finish_edge = reversed_tree_levels(start, finish)
            return {} unless bus

            geom = ray_geometry(offsets, edge)
            first = reversed_tree_leg(start, geom[:sx], geom[:sy], start_edge, finish)
            last = reversed_tree_leg(finish, geom[:ex], geom[:ey], finish_edge, start)
            reversed_tree_fields(model, first, last, bus, first[1] != start_edge)
          end

          def reversed_tree_fields(model, first, last, bus, beside)
            style = model.style.to_h.except(:umldi_route, :reversed_ends)
            style[:left_seated_source] = true if beside
            ends = [point_for(first), point_for(last)]
            { waypoints: points_to_waypoints([first, [first[0], bus], [last[0], bus], last]),
              source_anchor: ends[0], target_anchor: ends[1], source_port: ends[0], target_port: ends[1],
              style: style }
          end

          def reversed_tree_candidate?(model, link, bounds, offsets)
            model.connector_type == "Association" && model.style[:reversed_ends] &&
              model.style.to_h.values_at(:mode, :lwidth, :tree) == %w[3 0 V] &&
              ray_inputs?(bounds, offsets) && stored_bus_levels(link)
          end

          # A thin Mode 3 EDGE 2 Association whose single saved corner follows
          # the opposite placement order is clipped from each leg's stored
          # origin, as QEA's reversed_stored_corner does (5038EEE3).
          def reversed_corner_metadata(model, link, bounds, offsets, edge)
            return {} unless reversed_corner_candidate?(model, link, bounds, offsets, edge)

            boxes = bounds.values_at(:source, :target)
            origins = corner_origins(boxes, ray_geometry(offsets, edge))
            bend = Ea::Model::Point.new(**%i[x y].zip(intermediate_waypoints(link).first).to_h)
            ends = origins.zip(boxes).map { |origin, box| corner_exit(origin, bend, box) }
            ends.all? ? corner_fields(origins, bend, ends) : {}
          end

          def corner_fields(origins, bend, ends)
            { waypoints: points_to_waypoints([ends[0], bend, ends[1]].map { |point| [point.x, point.y] }),
              source_anchor: origins[0], target_anchor: origins[1] }
          end

          def corner_origins(boxes, geom)
            [stored_ray_origin(boxes[0], geom[:sx], geom[:sy]), stored_ray_origin(boxes[1], geom[:ex], geom[:ey])]
          end

          def corner_exit(origin, bend, box)
            inside_box?(origin, box) ? diagonal_corner_exit(origin, bend, box) : origin
          end

          def reversed_corner_candidate?(model, link, bounds, offsets, edge)
            model.connector_type == "Association" && model.style[:reversed_ends] && edge == 2 &&
              model.style.to_h.values_at(:mode, :lwidth, :tree) == ["3", "0", nil] &&
              ray_inputs?(bounds, offsets) && intermediate_waypoints(link).size == 1
          end

          # QEA seats the source labels of a reversed vertical lateral tree
          # ("LV") as if its source leg left to the left (5038EEE3 connector 207).
          def reversed_lateral_tree_metadata(model, _link, _bounds, _offsets, _edge)
            return {} unless model.connector_type == "Association" && model.style[:reversed_ends] &&
                             model.style[:tree] == "LV"

            { style: model.style.to_h.except(:reversed_ends).merge(left_seated_source: true) }
          end

          def points_to_waypoints(points)
            points.map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) }
          end
        end
      end
    end
  end
end
