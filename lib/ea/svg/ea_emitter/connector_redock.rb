# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Re-docks DIRECT (auto-routed straight, 2-waypoint) connectors
      # against the DRAWN element outlines captured during the element
      # render pass. EA clips connector rays at drawn boxes — grown
      # classifier heights and autosized package bodies — never the
      # stored logical rect (E58034A3: supplier right-edge dock 155
      # drawn vs 121 stored; 0CABA7D7's generalization far end 99
      # grown vs 84 stored).
      module ConnectorRedock
        module_function

        # Returns replacement waypoint pairs [source_edge, target_edge]
        # for the connector, or nil when the connector must keep its
        # parsed waypoints (not direct, not 2-point, unresolved ends,
        # self-loop, or no drawn bounds for either end).
        def pairs_for(connector, diagram, model_index, bounds_map)
          return nil unless bounds_map
          return nil unless direct?(connector)

          points = waypoint_pairs(connector)
          return nil unless points.size == 2

          rel = relationship_for(connector, model_index)
          return nil unless rel

          source_ref, target_ref = end_refs(rel)
          return nil unless source_ref && target_ref

          source_bounds = bounds_map[source_ref]
          target_bounds = bounds_map[target_ref]
          return nil unless source_bounds && target_bounds
          return nil if source_ref == target_ref

          [edge_point(source_bounds, target_bounds),
           edge_point(target_bounds, source_bounds)]
        end

        # EA never docks a horizontal connector line at the header
        # divider: endpoints landing on (box side edge, divider_y)
        # move down one row slot to divider_y + 13 - the first
        # attribute-row slot (E0C65C12/TK_PositionType: EA docks at
        # (451,90) where the stored route says (451,77) = our
        # divider; the (0,-13) endpoint-delta family, 57 lines).
        ROW_SLOT_PITCH = 13

        def row_slot_adjust(pairs, connector, diagram, model_index,
                            bounds_map, divider_y_by_ref)
          return nil unless bounds_map && divider_y_by_ref
          return nil unless pairs.size == 2

          rel = relationship_for(connector, model_index)
          return nil unless rel

          source_ref, target_ref = end_refs(rel)
          return nil unless source_ref && target_ref

          bounds = [bounds_map[source_ref], bounds_map[target_ref]]
          dividers = [divider_y_by_ref[source_ref],
                      divider_y_by_ref[target_ref]]
          return nil unless bounds.all? && dividers.all?

          changed = false
          adjusted = pairs.each_with_index.map do |(x, y), i|
            box = bounds[i]
            divider = dividers[i]
            at_edge = (x - box.x).abs <= 1 || (x - (box.x + box.width)).abs <= 1
            at_divider = (y - divider.to_f).abs <= 1
            if at_edge && at_divider
              changed = true
              [x, y + ROW_SLOT_PITCH]
            else
              [x, y]
            end
          end
          changed ? adjusted : nil
        end

        def direct?(connector)
          style = connector.style || {}
          %i[direct regenerated].any? { |k| style.key?(k) } ||
            %w[direct regenerated].any? { |k| style.key?(k) }
        end

        def waypoint_pairs(connector)
          (connector.waypoints || []).filter_map do |wp|
            next unless wp.position

            [wp.position.x, wp.position.y]
          end
        end

        def relationship_for(connector, model_index)
          return nil unless connector.relationship_ref && model_index

          model_index[connector.relationship_ref]
        end

        # Polymorphic relationship ends, in connector start→end
        # order: Generalization child→parent (specific_id/general_id),
        # Dependency client→supplier (client_id/supplier_id),
        # Association source_id/target_id.
        def end_refs(rel)
          if rel.respond_to?(:specific_id)
            [rel.specific_id, rel.general_id]
          elsif rel.respond_to?(:client_id)
            [rel.client_id, rel.supplier_id]
          else
            [rel.source_id, rel.target_id]
          end
        end

        # Center-to-center ray clipped at both box outlines.
        def edge_point(bounds, other_bounds)
          cx = bounds.x + bounds.width / 2
          cy = bounds.y + bounds.height / 2
          ocx = other_bounds.x + other_bounds.width / 2
          ocy = other_bounds.y + other_bounds.height / 2

          dx = ocx - cx
          dy = ocy - cy

          if dx.abs * bounds.height > dy.abs * bounds.width
            x = dx.positive? ? bounds.x + bounds.width : bounds.x
            y = safe_y(cx, cy, dx, dy, x)
            [x, y]
          else
            y = dy.positive? ? bounds.y + bounds.height : bounds.y
            x = safe_x(cx, cy, dx, dy, y)
            [x, y]
          end
        end

        def safe_y(cx, cy, dx, dy, x)
          return cy if dx.zero?

          cy + dy * (x - cx).abs / dx.abs
        end

        def safe_x(cx, cy, dx, dy, y)
          return cx if dy.zero?

          cx + dx * (y - cy).abs / dy.abs
        end
      end
    end
  end
end
