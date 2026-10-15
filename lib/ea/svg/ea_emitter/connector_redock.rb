# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Re-docks direct connectors and lateral tree target legs
      # against the DRAWN element outlines captured during the element
      # render pass. EA clips connector rays at drawn boxes — grown
      # classifier heights and autosized package bodies — never the
      # stored logical rect (E58034A3: supplier right-edge dock 155
      # drawn vs 121 stored; 0CABA7D7's generalization far end 99
      # grown vs 84 stored).
      module ConnectorRedock
        module_function

        # Returns replacement waypoint pairs for direct or lateral tree routes,
        # for the connector, or nil when the connector must keep its
        # parsed waypoints (not direct, not 2-point, unresolved ends,
        # self-loop, or no drawn bounds for either end).
        def pairs_for(connector, diagram, model_index, bounds_map)
          return nil unless bounds_map
          points = waypoint_pairs(connector)
          lateral = lateral_tree?(connector, points)
          return nil unless points.size == 2 || lateral

          rel = relationship_for(connector, model_index)
          return nil unless rel

          source_ref, target_ref = end_refs(rel)
          return nil unless source_ref && target_ref

          source_bounds = bounds_map[source_ref]
          target_bounds = bounds_map[target_ref]
          return nil unless source_bounds && target_bounds
          return nil if source_ref == target_ref

          if lateral
            target = lateral_target(points[1], target_bounds, connector.style[:tree])
            return target && [points[0], points[1], target]
          end

          anchors = [connector.source_anchor, connector.target_anchor]
          bounds = [source_bounds, target_bounds]
          original = clipped_pairs(bounds, anchors)
          return original unless stroke_outline?(connector, bounds)

          # EA docks these markers on the outer edge of the 2px box stroke.
          outline = bounds.map do |box|
            Ea::Model::Bounds.new(x: box.x - 1, y: box.y - 1,
                                  width: box.width + 2, height: box.height + 2)
          end
          candidate = clipped_pairs(outline, anchors)
          forward_route?(original, candidate) ? candidate : original
        end

        def lateral_tree?(connector, points)
          style = connector.style.to_h
          points.size == 3 && style[:mode] == "3" && style[:lwidth] == "2" &&
            %w[LV LH].include?(style[:tree]) &&
            %w[Generalization Aggregation].include?(connector.connector_type)
        end
        private_class_method :lateral_tree?

        # The bend selects the near target edge even when the boxes overlap.
        # Preserve the source leg and bend; only the final dock changes.
        def lateral_target(bend, bounds, tree)
          return nil unless bounds.width.positive? && bounds.height.positive?

          tree == "LV" ? vertical_target(bend, bounds) : horizontal_target(bend, bounds)
        end
        private_class_method :lateral_target

        def vertical_target(bend, bounds)
          x, y = bend
          return nil unless x.between?(bounds.x, bounds.x + bounds.width)

          edge = facing_coordinate(y, bounds.y, bounds.height)
          [x, edge] if edge
        end
        private_class_method :vertical_target

        def horizontal_target(bend, bounds)
          x, y = bend
          return nil unless y.between?(bounds.y, bounds.y + bounds.height)

          edge = facing_coordinate(x, bounds.x, bounds.width)
          [edge, y] if edge
        end
        private_class_method :horizontal_target

        def facing_coordinate(bend, start, extent)
          return start if bend < start
          return start + extent if bend > start + extent

          nil
        end
        private_class_method :facing_coordinate

        def stroke_outline?(connector, bounds)
          connector.style.to_h[:lwidth] == "2" &&
            bounds.all? { |box| box.width.positive? && box.height.positive? } &&
            outline_connector?(connector, bounds)
        end
        private_class_method :stroke_outline?

        def outline_connector?(connector, bounds)
          return true if %w[Generalization Aggregation].include?(connector.connector_type)

          return false unless stored_association?(connector) || offset_free_association?(connector)

          # Diagonal Association rounding and tree docks keep their existing rules.
          pairs = clipped_pairs(bounds, [connector.source_anchor, connector.target_anchor])
          pairs.first.zip(pairs.last).any? { |first, last| first == last }
        end
        private_class_method :outline_connector?

        def stored_association?(connector)
          style = connector.style.to_h
          connector.connector_type == "Association" && connector.has_geometry_offsets &&
            connector.source_port && connector.target_port &&
            %w[1 3].include?(style[:mode]) && !style[:tree]
        end
        private_class_method :stored_association?

        def offset_free_association?(connector)
          style = connector.style.to_h
          connector.connector_type == "Association" && style[:mode] == "3" && !style[:tree] &&
            %i[direct regenerated].none? { |key| style.key?(key) } && offset_free_anchors?(connector)
        end
        private_class_method :offset_free_association?

        def offset_free_anchors?(connector)
          !connector.has_geometry_offsets &&
            [connector.source_port, connector.target_port].all?(&:nil?) &&
            [connector.source_anchor, connector.target_anchor].all?
        end
        private_class_method :offset_free_anchors?

        def clipped_pairs(bounds, anchors)
          source, target = bounds
          source_anchor, target_anchor = anchors
          if source_anchor && target_anchor
            [anchor_exit(source_anchor, source, target_anchor),
             anchor_exit(target_anchor, target, source_anchor)]
          else
            [edge_point(source, target), edge_point(target, source)]
          end
        end
        private_class_method :clipped_pairs

        def forward_route?(original, candidate)
          before = original.first.zip(original.last).map { |start, finish| finish - start }
          after = candidate.first.zip(candidate.last).map { |start, finish| finish - start }
          before.zip(after).sum { |old, current| old * current }.positive?
        end
        private_class_method :forward_route?

        # Exit point of the anchor-to-anchor segment through a box's
        # outline: smallest positive t whose crossing lies on the
        # rectangle perimeter.
        def anchor_exit(anchor, bounds, other)
          ax, ay = anchor.x.to_f, anchor.y.to_f
          ox, oy = other.x.to_f, other.y.to_f
          dx, dy = ox - ax, oy - ay
          candidates = []
          if dx != 0
            [bounds.x, bounds.x + bounds.width].each do |x|
              t = (x - ax) / dx
              candidates << [t, x, ay + t * dy] if t.positive?
            end
          end
          if dy != 0
            [bounds.y, bounds.y + bounds.height].each do |y|
              t = (y - ay) / dy
              candidates << [t, ax + t * dx, y] if t.positive?
            end
          end
          on_perimeter = candidates.select do |_t, x, y|
            x >= bounds.x - 0.01 && x <= bounds.x + bounds.width + 0.01 &&
              y >= bounds.y - 0.01 && y <= bounds.y + bounds.height + 0.01
          end
          best = on_perimeter.min_by(&:first)
          # EA floors the dock coordinates (F851A657: 297.75 -> 297,
          # 433.7 -> 433) - a rounded-up dock is a visible miss.
          best ? [best[1].floor, best[2].floor] : [ax.floor, ay.floor]
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
          return nil if explicit_horizontal_source_dock?(pairs, connector)

          rel = relationship_for(connector, model_index)
          return nil unless rel

          source_ref, target_ref = end_refs(rel)
          return nil unless source_ref && target_ref

          bounds = [bounds_map[source_ref], bounds_map[target_ref]]
          dividers = [divider_y_by_ref[source_ref],
                      divider_y_by_ref[target_ref]]
          return nil unless bounds.all? && dividers.all?

          adjusted = row_slot_pairs(pairs, bounds, dividers)
          if stroke_outline?(connector, bounds) &&
             pairs == pairs_for(connector, diagram, model_index, bounds_map)
            original = clipped_pairs(bounds, [connector.source_anchor, connector.target_anchor])
            original_final = row_slot_pairs(original, bounds, dividers)
            adjusted = original_final if original != pairs && !forward_route?(original_final, adjusted)
          end
          adjusted == pairs ? nil : adjusted
        end

        # A supplied horizontal port already specifies its row. Moving it
        # to the next compartment row would discard that explicit coordinate.
        def explicit_horizontal_source_dock?(pairs, connector)
          return false unless explicit_horizontal_ray?(connector)

          connector.source_anchor.y == connector.target_anchor.y &&
            connector.source_port.y == connector.source_anchor.y &&
            pairs.first[1] == connector.source_port.y
        end
        private_class_method :explicit_horizontal_source_dock?

        def explicit_horizontal_ray?(connector)
          explicit_horizontal_ray_style?(connector) && connector.has_geometry_offsets &&
            connector.source_port && connector.target_port &&
            connector.source_anchor && connector.target_anchor
        end
        private_class_method :explicit_horizontal_ray?

        def explicit_horizontal_ray_style?(connector)
          style = connector.style.to_h
          %w[Generalization Aggregation].include?(connector.connector_type) &&
            style[:mode] == "3" && !style[:tree] && !style[:direct] && !style[:regenerated]
        end
        private_class_method :explicit_horizontal_ray_style?

        def row_slot_pairs(pairs, bounds, dividers)
          pairs.each_with_index.map do |(x, y), index|
            row_slot?(x, y, bounds[index], dividers[index]) ? [x, y + ROW_SLOT_PITCH] : [x, y]
          end
        end
        private_class_method :row_slot_pairs

        def row_slot?(x_position, y_position, bounds, divider)
          at_edge = (x_position - bounds.x).abs <= 1 ||
                    (x_position - (bounds.x + bounds.width)).abs <= 1
          at_edge && (y_position - divider.to_f).abs <= 1
        end
        private_class_method :row_slot?

        def direct?(connector)
          style = connector.style || {}
          %i[direct regenerated].any? { |k| style.key?(k) } ||
            %w[direct regenerated].any? { |k| style.key?(k) }
        end

        # EXPERIMENT: every auto-laid 2-waypoint connector re-docks
        # as the center-to-center ray clipped at the drawn outlines.
        def two_point?(connector)
          (connector.waypoints || []).size == 2
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
            [x, y.floor]
          else
            y = dy.positive? ? bounds.y + bounds.height : bounds.y
            x = safe_x(cx, cy, dx, dy, y)
            [x.floor, y]
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
