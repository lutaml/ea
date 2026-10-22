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
            route = reversed_tree_points(start, finish, ray_geometry(offsets, edge), stored_bus_levels(link))
            return {} unless route

            reversed_tree_fields(model, route[0], route[1])
          end

          def reversed_tree_fields(model, points, beside)
            style = model.style.to_h.except(:umldi_route, :reversed_ends)
            style[:left_seated_source] = true if beside
            ends = [point_for(points.first), point_for(points.last)]
            { waypoints: points_to_waypoints(points),
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

            origins, points = reversed_corner_points(bounds.values_at(:source, :target), ray_geometry(offsets, edge),
                                                     intermediate_waypoints(link).first)
            return {} unless points

            { waypoints: points_to_waypoints(points.map { |point| [point.x, point.y] }),
              source_anchor: origins[0], target_anchor: origins[1] }
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
