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
        # self-loop, an authoritative UMLDI route, or no drawn bounds for either end).
        def pairs_for(connector, diagram, model_index, bounds_map)
          return nil unless bounds_map

          tether = association_class_pairs(connector, bounds_map)
          return tether if tether

          return nil if connector.style.to_h[:umldi_route] == true

          points = waypoint_pairs(connector)
          lateral = lateral_tree?(connector, points)
          trunk = trunk_tree?(connector, points)
          return nil unless points.size == 2 || lateral || trunk

          rel = relationship_for(connector, model_index)
          return nil unless rel

          source_ref, target_ref = end_refs(rel)
          return nil unless source_ref && target_ref

          source_bounds = bounds_map[source_ref]
          target_bounds = bounds_map[target_ref]
          return nil unless source_bounds && target_bounds
          return nil if source_ref == target_ref
          if flush_overlap_ray?(connector)
            return clipped_pairs([source_bounds, target_bounds], [connector.source_anchor, connector.target_anchor])
          end
          return trunk_pairs(points, source_bounds, target_bounds, connector.style[:tree]) if trunk

          square = OrthogonalRay.pairs_for(connector, source_bounds, target_bounds)
          return square if square

          if lateral
            target = lateral_target(points[1], target_bounds, connector.style[:tree])
            return target && [points[0], points[1], target]
          end

          return nil if flush_lateral_line?(connector, points, source_bounds, target_bounds)

          bounds = [source_bounds, target_bounds]
          anchors = drawn_center_anchors(connector, diagram, [source_ref, target_ref], bounds)
          original = clipped_pairs(bounds, anchors)
          unless stroke_outline?(connector, bounds) || overlap_ray?(connector) ||
                 bordered_outline?(connector, diagram, [source_ref, target_ref], bounds)
            pairs = default_square_pairs(connector, points, source_bounds, target_bounds, original)
            return stored_top_pairs(connector, source_bounds, pairs)
          end

          refs = [source_ref, target_ref]
          duids = connector.style.to_h.values_at(:soid, :eoid)
          outline = bounds.each_with_index.map do |box, index|
            outline_bounds(box, diagram, refs[index], duids[index])
          end
          candidate = clipped_pairs(outline, anchors)
          candidate[0] = external_source_point(connector, outline.first, anchors, candidate.first)
          expanded = forward_route?(original, candidate)
          pairs = expanded ? candidate : original
          target = expanded ? outline.last : target_bounds
          pairs = default_square_pairs(connector, points, source_bounds, target, pairs)
          source = expanded ? outline.first : source_bounds
          pairs = stored_top_pairs(connector, source, pairs)
          auto_port_elbow_pairs(connector, source, target, pairs)
        end

        def drawn_center_anchors(connector, diagram, refs, bounds)
          anchors = [connector.source_anchor, connector.target_anchor]
          return anchors unless connector.style.to_h[:centered_origin_ray] == true

          duids = connector.style.to_h.values_at(:soid, :eoid)
          anchors.each_with_index.map do |anchor, index|
            saved = unique_logical_bounds(diagram, refs[index], duids[index])
            centered_anchor(anchor, saved, bounds[index])
          end
        end
        private_class_method :drawn_center_anchors

        def unique_logical_bounds(diagram, ref, duid)
          placements = end_placements(diagram, ref, duid)
          placements.first.bounds if placements.size == 1
        end
        private_class_method :unique_logical_bounds

        def centered_anchor(anchor, saved, drawn)
          return anchor unless anchor && saved

          Ea::Model::Point.new(x: anchor.x + center_shift(saved, drawn, :x, :width),
                               y: anchor.y + center_shift(saved, drawn, :y, :height))
        end
        private_class_method :centered_anchor

        def center_shift(saved, drawn, coordinate, size)
          drawn.public_send(coordinate) + drawn.public_send(size) / 2 -
            saved.public_send(coordinate) - saved.public_send(size) / 2
        end
        private_class_method :center_shift

        # A tether joins its saved association anchor to the facing
        # side-center of the attached class, rather than to the other proxy.
        def association_class_pairs(connector, bounds_map)
          bounds = bounds_map[connector.style.to_h[:association_class_ref]]
          anchor = connector.source_anchor
          return nil unless bounds && anchor

          [[anchor.x, anchor.y], association_class_dock(bounds, anchor)]
        end
        private_class_method :association_class_pairs

        def association_class_dock(bounds, anchor)
          center = association_class_center(bounds)
          if horizontal_association_class?(bounds, anchor, center)
            [association_class_edge_coordinate(bounds.x, bounds.width, anchor.x), center[1]]
          else
            [center[0], association_class_edge_coordinate(bounds.y, bounds.height, anchor.y)]
          end
        end
        private_class_method :association_class_dock

        def association_class_center(bounds)
          [bounds.x + bounds.width / 2, bounds.y + bounds.height / 2]
        end
        private_class_method :association_class_center

        def horizontal_association_class?(bounds, anchor, center)
          (anchor.x - center[0]).abs * bounds.height > (anchor.y - center[1]).abs * bounds.width
        end
        private_class_method :horizontal_association_class?

        def association_class_edge_coordinate(origin, size, anchor)
          anchor > origin + size / 2 ? origin + size : origin
        end
        private_class_method :association_class_edge_coordinate

        # Auto routing turns at the clipped target column when the source
        # leaves a side edge and the target enters through its top or bottom.
        def auto_port_elbow_pairs(connector, source, target, pairs)
          return pairs unless connector.style.to_h[:auto_port_elbow] == true

          first, last = pairs
          return pairs unless on_side_edge?(first, source) &&
                              [target.y, target.y + target.height].include?(last[1]) &&
                              last[0].between?(target.x, target.x + target.width)
          return pairs if first[0] == last[0] || first[1] == last[1]

          [first, [last[0], first[1]], last]
        end
        private_class_method :auto_port_elbow_pairs

        # An external saved ray can cross two source edges; retain its
        # clockwise perimeter choice instead of the nearest crossing.
        def external_source_point(connector, source, anchors, fallback)
          style = connector.style.to_h
          return fallback unless style[:stored_association_ray] == true && style[:lwidth] == "2"

          first, last = anchors
          return fallback if first.x.between?(source.x, source.x + source.width) &&
                             first.y.between?(source.y, source.y + source.height)

          anchor_exit(first, source, last, perimeter: true)
        end
        private_class_method :external_source_point

        # EDGE=1 explicitly seats an external source ray on the top edge;
        # its first contact can instead be the bottom when its origin is below.
        def stored_top_pairs(connector, source, pairs)
          return pairs unless connector.connector_type == "Association" &&
                              connector.style.to_h[:stored_top_dock] == true

          first = connector.source_anchor
          last = connector.target_anchor
          return pairs unless first && last && first.y != last.y

          ratio = (source.y - first.y).to_f / (last.y - first.y)
          x_position = first.x + ratio * (last.x - first.x)
          return pairs unless ratio.between?(0, 1) &&
                              x_position.between?(source.x, source.x + source.width)

          proposed = [[x_position.floor, source.y], pairs.last]
          forward_route?(pairs, proposed) ? proposed : pairs
        end
        private_class_method :stored_top_pairs

        # A square ray with an omitted source offset keeps its chosen side
        # edge and projects that end to the clipped target's horizontal row.
        def default_square_pairs(connector, points, source, target, pairs)
          return pairs unless connector.style.to_h[:default_square_ray] == true
          return pairs unless points.first[1] == points.last[1] &&
                              on_side_edge?(points.first, source) && on_side_edge?(pairs.last, target)

          first = [points.first[0], pairs.last[1]]
          return pairs unless on_side_edge?(first, source)

          proposed = [first, pairs.last]
          forward_route?(points, proposed) ? proposed : pairs
        end
        private_class_method :default_square_pairs

        # A horizontal lateral tree the QEA builder derived as one level
        # line (internal style flag) keeps it between the facing side edges.
        def flush_lateral_line?(connector, points, source, target)
          style = connector.style.to_h
          return false unless style[:derived_lateral_line] && style[:mode] == "3" &&
                              style[:tree] == "LH" && points.size == 2 &&
                              %w[Association Generalization].include?(connector.connector_type)
          return false unless connector.source_anchor && connector.target_anchor

          first, last = points
          pinned = [[connector.source_anchor.x, connector.source_anchor.y],
                    [connector.target_anchor.x, connector.target_anchor.y]]
          pinned == [first, last] && first[1] == last[1] &&
            on_side_edge?(first, source) && on_side_edge?(last, target)
        end
        private_class_method :flush_lateral_line?

        def on_side_edge?(point, bounds)
          [bounds.x, bounds.x + bounds.width].include?(point[0]) &&
            point[1].between?(bounds.y, bounds.y + bounds.height)
        end
        private_class_method :on_side_edge?

        def lateral_tree?(connector, points)
          style = connector.style.to_h
          points.size == 3 && style[:mode] == "3" && style[:lwidth] == "2" &&
            %w[LV LH].include?(style[:tree]) &&
            %w[Generalization Aggregation].include?(connector.connector_type)
        end
        private_class_method :lateral_tree?

        # The QEA builder already docks the Generalization, Aggregation and
        # Association trunks; the other types (Dependency, Nesting, ...) keep
        # their stored ends. A flush (width 0) vertical or horizontal trunk
        # runs axis-aligned into both boxes, so a stored end off that axis or
        # on the far edge of its box is a lost dock the adjacent bend names.
        BUILDER_TRUNK_TYPES = %w[Generalization Aggregation Association].freeze

        def trunk_tree?(connector, points)
          style = connector.style.to_h
          points.size >= 3 && style[:mode] == "3" && style[:lwidth] == "0" &&
            %w[V H].include?(style[:tree]) && !BUILDER_TRUNK_TYPES.include?(connector.connector_type)
        end
        private_class_method :trunk_tree?

        def trunk_pairs(points, source, target, tree)
          first = trunk_dock(points[0], points[1], source, tree)
          last = trunk_dock(points[-1], points[-2], target, tree)
          return nil if first == points[0] && last == points[-1]

          [first, *points[1..-2], last]
        end
        private_class_method :trunk_pairs

        def trunk_dock(end_point, bend, bounds, tree)
          return end_point unless bounds.width.positive? && bounds.height.positive?

          dock = tree == "V" ? vertical_target(bend, bounds) : horizontal_target(bend, bounds)
          dock || end_point
        end
        private_class_method :trunk_dock

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
          (connector.style.to_h[:lwidth] == "2" || default_model_connector?(connector) ||
           connector.connector_type == "NoteLink") &&
            bounds.all? { |box| box.width.positive? && box.height.positive? } &&
            outline_connector?(connector, bounds)
        end
        private_class_method :stroke_outline?

        # The builder certifies the empty flush route's shared row and nominal docks.
        def flush_overlap_ray?(connector)
          connector.connector_type == "Association" && connector.style.to_h[:flush_overlap_ray] == true
        end
        private_class_method :flush_overlap_ray?

        # The QEA builder marks Mode 2 overlap rays for outer-stroke docking.
        def overlap_ray?(connector)
          connector.connector_type == "Association" && connector.style.to_h[:overlap_ray] == true
        end
        private_class_method :overlap_ray?

        # The QEA builder flags a model relationship drawn without any
        # diagram link row; its docks follow the resolved element borders.
        def default_model_connector?(connector)
          connector.style.to_h[:phantom_outline] == true && !connector.has_geometry_offsets &&
            %w[Aggregation Association].include?(connector.connector_type)
        end
        private_class_method :default_model_connector?

        # Thin connectors between explicitly bordered elements stop on the outer
        # edge of their 2px borders, including package imports.
        def bordered_outline?(connector, diagram, refs, bounds)
          style = connector.style.to_h
          return false unless style[:lwidth] == "0" && !style[:tree]
          return false unless %w[Generalization Aggregation Association Dependency Package].include?(
            connector.connector_type
          )
          return false unless bounds.all? { |box| box.width.positive? && box.height.positive? }

          ends = [[refs.first, style[:soid]], [refs.last, style[:eoid]]]
          ends.all? { |ref, duid| border_width?(diagram, ref, duid, 2) }
        end
        private_class_method :bordered_outline?

        # Every placement of the element (the DUID-matched one when the
        # connector names it) must declare the same border width.
        def border_width?(diagram, ref, duid, width)
          placed = end_placements(diagram, ref, duid)
          placed.any? && placed.all? { |el| el.line_width == width || el.style.to_h[:lwth] == width.to_s }
        end
        private_class_method :border_width?

        # EA seats docks on whole pixels; a 1px border keeps the geometric edge.
        def outline_bounds(box, diagram, ref, duid)
          inset = (outline_width(diagram, ref, duid) / 2.0).floor
          Ea::Model::Bounds.new(x: box.x - inset, y: box.y - inset,
                                width: box.width + 2 * inset, height: box.height + 2 * inset)
        end
        private_class_method :outline_bounds

        def outline_width(diagram, ref, duid)
          widths = end_placements(diagram, ref, duid).map do |element|
            effective_border_width(element, diagram)
          end.uniq
          widths.size == 1 ? widths.first : diagram.theme.stroke_width
        end
        private_class_method :outline_width

        def effective_border_width(element, diagram)
          return element.line_width if element.line_width && element.line_width >= 0

          raw = element.style.to_h[:lwth]
          return raw.to_i if raw && raw.to_i >= 0

          diagram.theme.stroke_width
        end
        private_class_method :effective_border_width

        def end_placements(diagram, ref, duid)
          placed = Array(diagram&.elements).select { |el| el.model_element_ref == ref }
          named = placed.select { |el| duid && el.duid.to_s.casecmp?(duid.to_s) }
          named.empty? ? placed : named
        end
        private_class_method :end_placements

        def outline_connector?(connector, bounds)
          return true if default_model_connector?(connector)
          return true if %w[Generalization Aggregation NoteLink].include?(connector.connector_type)

          return true if association_ray_outline?(connector)
          return false unless stored_association?(connector) || offset_free_association?(connector)

          # Diagonal Association rounding and tree docks keep their existing rules.
          pairs = clipped_pairs(bounds, [connector.source_anchor, connector.target_anchor])
          pairs.first.zip(pairs.last).any? { |first, last| first == last }
        end
        private_class_method :outline_connector?

        # The QEA builder marks the stored Association rays it produced;
        # their diagonal docks sit on the outer stroke edge like the
        # axis-aligned ones. Unmarked diagonals keep the legacy docking.
        def association_ray_outline?(connector)
          connector.connector_type == "Association" &&
            connector.style.to_h[:association_ray_outline] == true
        end
        private_class_method :association_ray_outline?

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

        # Interior rays use the nearest forward exit. External saved sources
        # can request the first intersecting edge in clockwise perimeter order.
        def anchor_exit(anchor, bounds, other, perimeter: false)
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
          best = if perimeter
                   on_perimeter.min_by { |_t, x, y| perimeter_order(x, y, bounds) }
                 else
                   on_perimeter.min_by(&:first)
                 end
          # EA floors the dock coordinates (F851A657: 297.75 -> 297,
          # 433.7 -> 433) - a rounded-up dock is a visible miss.
          best ? [best[1].floor, best[2].floor] : [ax.floor, ay.floor]
        end

        def perimeter_order(point_x, point_y, bounds)
          return 0 if point_y == bounds.y
          return 1 if point_x == bounds.x + bounds.width
          return 2 if point_y == bounds.y + bounds.height

          3
        end
        private_class_method :perimeter_order

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
          return nil if connector.style.to_h[:umldi_route] == true
          return nil unless pairs.size == 2
          return nil if flush_overlap_ray?(connector)
          return nil if explicit_association_ray?(pairs, connector)
          return nil if connector.style.to_h[:stored_origin_ray] == true

          rel = relationship_for(connector, model_index)
          return nil unless rel

          source_ref, target_ref = end_refs(rel)
          return nil unless source_ref && target_ref

          bounds = [bounds_map[source_ref], bounds_map[target_ref]]
          dividers = [divider_y_by_ref[source_ref],
                      divider_y_by_ref[target_ref]]
          return nil unless bounds.all? && dividers.all?
          return nil if flush_lateral_line?(connector, pairs, *bounds)

          preserve_source = explicit_horizontal_source_dock?(pairs, connector)
          adjusted = row_slot_pairs(pairs, bounds, dividers, preserve_source: preserve_source)
          if stroke_outline?(connector, bounds) &&
             pairs == pairs_for(connector, diagram, model_index, bounds_map)
            original = clipped_pairs(bounds, [connector.source_anchor, connector.target_anchor])
            original_final = row_slot_pairs(original, bounds, dividers, preserve_source: preserve_source)
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

        # The QEA producer certifies stored Association rays from their
        # endpoint origins. Keep the clipped ray even when a diagonal end
        # coincides with a header divider. Other callers need a certified
        # horizontal port before bypassing compartment row seating.
        def explicit_association_ray?(pairs, connector)
          produced = connector.style.to_h[:stored_association_ray] == true
          return true if produced

          certified_association_ray?(pairs, connector)
        end

        def certified_association_ray?(pairs, connector)
          return false unless explicit_horizontal_ray?(connector, %w[Association])

          connector.source_anchor.y == connector.target_anchor.y &&
            connector.source_port.y == connector.source_anchor.y &&
            pairs.first[1] == pairs.last[1]
        end
        private_class_method :certified_association_ray?
        private_class_method :explicit_association_ray?

        def explicit_horizontal_ray?(connector, types = %w[Generalization Aggregation])
          explicit_horizontal_ray_style?(connector, types) && connector.has_geometry_offsets &&
            connector.source_port && connector.target_port &&
            connector.source_anchor && connector.target_anchor
        end
        private_class_method :explicit_horizontal_ray?

        def explicit_horizontal_ray_style?(connector, types)
          style = connector.style.to_h
          types.include?(connector.connector_type) &&
            style[:mode] == "3" && !style[:tree] && !style[:direct] && !style[:regenerated]
        end
        private_class_method :explicit_horizontal_ray_style?

        def row_slot_pairs(pairs, bounds, dividers, preserve_source: false)
          pairs.each_with_index.map do |(x, y), index|
            next [x, y] if preserve_source && index.zero?

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
        # Realization realizing_id/contract_id,
        # Dependency client→supplier (client_id/supplier_id),
        # Association source_id/target_id.
        def end_refs(rel)
          refs = case rel
                 when Ea::Model::Generalization then [rel.specific_id, rel.general_id]
                 when Ea::Model::Realization then [rel.realizing_id, rel.contract_id]
                 when Ea::Model::Dependency then [rel.client_id, rel.supplier_id]
                 else [rel.source_id, rel.target_id]
                 end
          refs.map { |ref| diagram_ref(ref) }
        end

        # A package is `EAPK_<guid>` in the XMI model but is placed on a
        # diagram as `EAID_<guid>`; key its ends by the diagram spelling.
        def diagram_ref(ref)
          ref.is_a?(String) && ref.start_with?("EAPK_") ? "EAID_#{ref[5..]}" : ref
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
