# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits the labels layer: connector role/multiplicity end
      # labels plus midpoint stereotype labels for non-association
      # connectors.
      #
      # This class is the orchestrator. The actual label-shaping
      # logic lives in dedicated, MECE collaborators under
      # `Ea::Svg::EaEmitter::Label`:
      #
      #   Label::EndLabel      - role + «property» + mult at LLT/LRT
      #   Label::MidpointLabel - «stereotype» at connector midpoint
      #   Label::Registry      - dispatch by relationship kind (OCP)
      #
      # Theme is read once and threaded to collaborators so the
      # rendering rules (font family/size, fill color) live in one
      # place.
      class Labels
        DEFAULT_FAMILY = "Yu Gothic UI"
        DEFAULT_SIZE = 13

        attr_reader :diagram, :canvas, :model_index, :theme, :document,
                    :drawn_bounds, :divider_y_by_ref

        def initialize(diagram, canvas: nil, model_index: nil, theme: nil,
                       document: nil, drawn_bounds: nil, divider_y_by_ref: nil)
          @diagram = diagram
          @canvas = canvas
          @model_index = model_index
          @theme = theme || Ea::Theme::Registry.default
          @document = document
          @drawn_bounds = drawn_bounds
          @divider_y_by_ref = divider_y_by_ref
        end

        def render
          texts = visible_connectors.flat_map { |c| texts_for(c) }
          return "" if texts.empty?

          %(<g style="stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00">\n#{texts.join("\n")}\n</g>)
        end

        private

        def visible_connectors
          (diagram.connectors || []).select(&:renderable?)
        end

        def texts_for(connector)
          # EA never labels NoteLink connectors — the note text lives
          # in t_connector.Name but renders only inside the Note box.
          return [] if connector.connector_type.to_s.casecmp("NoteLink").zero?

          points = label_points(connector)
          return [] if points.size < 2

          texts = []

          # Midpoint label: stereotype «import», or relationship
          # Name ("Association A"). Renders at the path midpoint.
          mid_text = midpoint_renderer.text_for(connector, points)
          texts << mid_text if mid_text

          # End-labels: role name + «property» + multiplicity at
          # positioned LLT/LRT boxes. Only for associations without
          # a midpoint stereotype (stereotyped associations route
          # to midpoint only).
          if registry.end_label?(connector)
            end_label_texts(connector, points).each { |t| texts << t }
          end

          texts
        end

        def end_label_texts(connector, points)
          source_pt = points.first
          target_pt = points.last
          boxes = connector.label_boxes || {}
          tree = tree_shaped?(points)

          stored_src = end_boxes(boxes, :llt, :llb)
          stored_tgt = end_boxes(boxes, :lrt, :lrb)
          stored_labels = !(stored_src.nil? && stored_tgt.nil?)
          src_tb, src_mb = stored_src || unstored_label_boxes(points, :source, stored_labels)
          tgt_tb, tgt_mb = stored_tgt || unstored_label_boxes(points, :target, stored_labels)

          texts = []
          end_renderer.texts(text_box: src_tb, mult_box: src_mb,
                             anchor: source_pt, connector: connector,
                             end_kind: :source, tree: tree && tree[:source],
                             heading: (stored_src || stored_labels) && source_heading(connector, points),
                             stored_labels: stored_labels).each { |t| texts << t }
          end_renderer.texts(text_box: tgt_tb,
                             mult_box: tgt_mb,
                             anchor: target_pt, connector: connector,
                             end_kind: :target, tree: tree && tree[:target],
                             heading: (stored_tgt || stored_labels) && target_heading(connector, points),
                             stored_labels: stored_labels).each { |t| texts << t }
          texts
        end

        # A connector that stores label boxes for only one end seats the
        # other end's labels at its anchor, like a stored zero offset.
        def unstored_label_boxes(points, end_kind, stored_labels)
          return default_label_boxes(points, end_kind) unless stored_labels

          [{ "ox" => 0, "oy" => 0, "alignment" => 0 }, { "ox" => 0, "oy" => 0, "alignment" => 0 }]
        end

        # EA tree routes are a perfect L: source-exit horizontal into
        # the corner, vertical trunk into the target dock. Returns
        # per-end flags when the connector matches, else nil.
        def tree_shaped?(points)
          return nil unless points.size == 3
          return nil unless points[0][1] == points[1][1] &&
                           points[1][0] == points[2][0]

          { source: true, target: true }
        end

        # A diagonal clipped leg keeps the seat of its unambiguous exit face.
        # Unknown faces retain the stored-upward fallback.
        def source_heading(connector, points)
          heading = leg_heading(points)
          return heading unless points.size == 2 && heading.none?(&:zero?)

          box = source_dock_bounds(connector)
          face = box && source_dock_heading(connector, points.first, box)
          return face if face && face_leads_leg?(connector, face, heading, box)

          stored_upward_heading(connector, heading)
        end

        # A target dock that clips an axis-aligned stored leg into a slight
        # diagonal keeps the stored leg's direction.
        def target_heading(connector, points)
          heading = leg_heading(points.reverse)
          return heading unless points.size == 2 && heading.none?(&:zero?)

          stored = waypoint_pairs(connector)
          return heading unless stored.size == 2

          original = leg_heading(stored.reverse)
          original.any?(&:zero?) ? original : heading
        end

        # A saved external ray enters the source through the face it first
        # meets, even when the clipped leg then runs back across the box.
        def face_leads_leg?(connector, face, heading, box)
          anchor = connector.source_anchor
          if face == [0, 1] && anchor && anchor.y > box.y + box.height &&
             connector.style.to_h[:stored_association_ray] == true
            return true
          end

          face.zip(heading).any? { |axis, delta| (axis * delta).positive? }
        end

        def stored_upward_heading(connector, heading)
          return heading unless heading[1].negative?

          stored = waypoint_pairs(connector)
          return heading unless stored.size == 2

          original = leg_heading(stored)
          original[0].zero? && original[1].negative? ? original : heading
        end

        def source_dock_bounds(connector)
          return nil unless model_index && drawn_bounds

          relationship = model_index[connector.relationship_ref]
          return nil unless relationship

          source, target = ConnectorRedock.end_refs(relationship)
          return nil if source == target
          return nil unless drawn_bounds[target]

          drawn_bounds[source]
        end

        # Saved rays can start outside the box. Project onto its boundary;
        # corners stay ambiguous and the face must still lead the emitted leg.
        def source_dock_heading(connector, point, box)
          return dock_face_heading(point, box) unless connector.style.to_h[:association_ray_outline] == true
          return nil unless box.width.positive? && box.height.positive?

          dock_face_heading(projected_dock_point(point, box), box)
        end

        def projected_dock_point(point, box)
          [point[0].clamp(box.x, box.x + box.width), point[1].clamp(box.y, box.y + box.height)]
        end

        def dock_face_heading(point, box)
          return nil unless box.width.positive? && box.height.positive?

          vertical_dock_heading(point, box) || horizontal_dock_heading(point, box)
        end

        def vertical_dock_heading(point, box)
          x, y = point
          left = box.x
          return nil unless x > left && x < left + box.width

          top = box.y
          return [0, -1] if [top, top - 1].include?(y)

          bottom = top + box.height
          [0, 1] if [bottom, bottom + 1].include?(y)
        end

        def horizontal_dock_heading(point, box)
          x, y = point
          top = box.y
          return nil unless y > top && y < top + box.height

          left = box.x
          return [-1, 0] if [left, left - 1].include?(x)

          right = left + box.width
          [1, 0] if [right, right + 1].include?(x)
        end

        def leg_heading(points)
          [points[1][0] - points[0][0], points[1][1] - points[0][1]]
        end

        def end_boxes(boxes, text_key, mult_key)
          return nil if boxes[text_key].nil? && boxes[mult_key].nil?

          [boxes[text_key], boxes[mult_key]]
        end

        # EA's default label placement for connectors without stored
        # label boxes: role name 5px along the line and 31px below it,
        # multiplicity 18px along and 21px above (screen-down coords).
        # Derived from 219 labels across EA-published reference SVGs.
        def default_label_boxes(points, end_kind)
          e = end_kind == :source ? points.first : points.last
          other = end_kind == :source ? points[1] : points[-2]
          return [nil, nil] unless e && other

          ux = other[0] - e[0]
          uy = other[1] - e[1]
          len = Math.sqrt(ux**2 + uy**2)
          return [nil, nil] if len < 0.5

          ux /= len
          uy /= len
          vx = uy
          vy = -ux
          role_box = { "ox" => (5 * ux - 31 * vx).round,
                       "oy" => (5 * uy - 31 * vy).round }
          mult_box = { "ox" => (18 * ux + 21 * vx).round,
                       "oy" => (18 * uy + 21 * vy).round }
          [role_box, mult_box]
        end

        def registry
          @registry ||= Label::Registry.new(model_index: model_index)
        end

        def end_renderer
          @end_renderer ||= Label::EndLabel.new(
            canvas: canvas,
            model_index: model_index,
            document: document,
            theme: theme,
            font_family: label_font_family,
            font_size: label_font_size,
            font_unit: theme.label_font_size_unit
          )
        end

        def midpoint_renderer
          @midpoint_renderer ||= Label::MidpointLabel.new(
            canvas: canvas,
            model_index: model_index,
            font_family: label_font_family,
            font_size: label_font_size,
            font_unit: theme.label_font_size_unit
          )
        end

        # Two-point routes are clipped during emission, after their stored
        # waypoints were parsed. End-label offsets follow the same final dock.
        def label_points(connector)
          points = waypoint_pairs(connector)
          return points unless points.size == 2

          points = ConnectorRedock.pairs_for(connector, diagram, model_index,
                                             drawn_bounds) || points
          ConnectorRedock.row_slot_adjust(points, connector, diagram,
                                          model_index, drawn_bounds,
                                          divider_y_by_ref) || points
        end

        def waypoint_pairs(connector)
          (connector.waypoints || []).filter_map do |w|
            next unless w.position

            [w.position.x, w.position.y]
          end
        end

        def label_font_family
          theme.label_font_family || DEFAULT_FAMILY
        end

        def label_font_size
          theme.label_font_size || DEFAULT_SIZE
        end
      end
    end
  end
end
