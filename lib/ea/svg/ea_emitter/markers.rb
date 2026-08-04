# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits marker `<polygon>` and `<path>` elements per connector,
      # matching EA's encoding rules. Returns an Array of `Layer`
      # structs bucketed by marker style.
      #
      # Layer style keys:
      #   - :diamond_filled  → 4-pt <polygon>, black fill
      #   - :triangle_open   → 3-pt <polygon>, white fill
      #   - :arrow           → 3-pt <path>, no fill (shares style with
      #     connector lines — same stroke, no fill)
      #
      # Default mode (`grouped: true`) consolidates all markers of
      # the same style into ONE `<g>`. Pass `grouped: false` for
      # per-connector grouping.
      class Markers
        DIAMOND_HALF_W = 5
        DIAMOND_HALF_H = 10
        TRI_HALF_BASE = 6
        TRI_HEIGHT = 11
        ARROW_HALF_BASE = 6
        ARROW_HEIGHT = 11

        attr_reader :diagram, :model_index, :canvas, :grouped, :stroke_width

        def initialize(diagram, model_index:, canvas: nil, grouped: true, stroke_width: 2)
          @diagram = diagram
          @model_index = model_index
          @canvas = canvas
          @grouped = grouped
          @stroke_width = stroke_width
        end

        def layers
          entries = visible_connectors.flat_map { |c| entries_for(c) }
          return [] if entries.empty?

          if grouped
            entries.group_by(&:style_key).map do |key, grouped_entries|
              # EA emits ONE marker per connector regardless of
              # anchor overlap. Verified against plateau Bridge
              # diagram: 9 generalizations fanning from the same
              # parent anchor produce 9 distinct triangle polygons
              # at the same coordinates. The earlier "dedup by
              # anchor" hypothesis is disproven by reference SVGs.
              Layer.new(style_key: key,
                        style: style_for(key),
                        body: grouped_entries.map(&:body).join("\n  "))
            end
          else
            entries.map { |e| Layer.new(style_key: e.style_key, style: style_for(e.style_key), body: e.body) }
          end
        end

        def render
          layers.map(&:to_svg).join("\n")
        end

        # Backwards-compatible API: count of marker bodies emitted.
        def count_for(connector)
          return 0 if connector.hidden
          return 0 unless connector.waypoints&.any?(&:position)

          entries_for(connector).size
        end

        private

        # Entry pairs the rendered SVG body with the structural
        # anchor (rounded integer [x, y] pair). Anchor is retained
        # for future use (e.g. overlap diagnostics) but no longer
        # drives dedup — EA emits one marker per connector.
        Entry = Struct.new(:style_key, :body, :anchor,
                           :connector_waypoint_count,
                           keyword_init: true) do
          def hash
            anchor.hash
          end

          def eql?(other)
            other.is_a?(Entry) && anchor == other.anchor
          end
        end

        # OCP registries for marker shapes. Adding a new marker shape
        # = adding one entry to SHAPE_REGISTRY, not editing 3 case/when
        # branches. Each entry carries the style_key and a render
        # lambda that knows how to draw the shape.
        #
        # Style keys (:diamond_filled, :triangle_open, :connector_line)
        # map to CSS strings via STYLE_MAP below.
        SHAPE_REGISTRY = {
          diamond: {
            style_key: :diamond_filled,
            render: ->(m, anchor, base) { m.diamond_polygon(anchor, base) }
          },
          triangle: {
            style_key: :triangle_open,
            render: ->(m, anchor, base) { m.triangle_polygon(anchor, base) }
          },
          plus: {
            style_key: :connector_line,
            render: ->(m, anchor, _base) { m.plus_path(anchor) }
          },
          arrow: {
            style_key: :connector_line,
            render: ->(m, anchor, base) { m.arrow_path(anchor, base) }
          },
          package_anchor: {
            style_key: :connector_line,
            render: ->(m, anchor, base) { m.package_anchor_path(anchor, base) }
          }
        }.freeze

        # Style key → (fill, opacity) pair. The common stroke prefix
        # is shared, so only the fill and opacity vary.
        STYLE_MAP = {
          diamond_filled: { fill: "#000000", opacity: "1.00" },
          triangle_open: { fill: "#FFFFFF", opacity: "1.00" },
          connector_line: { fill: "#000000", opacity: "0.00" }
        }.freeze

        def style_for(key)
          spec = STYLE_MAP[key]
          return nil unless spec

          "stroke-width:#{stroke_width};stroke-linecap:round;stroke-linejoin:bevel; " \
            "fill:#{spec[:fill]};fill-opacity:#{spec[:opacity]}; " \
            "stroke:#000000; stroke-opacity:1.00"
        end

        def visible_connectors
          (diagram.connectors || []).select(&:renderable?)
        end

        def entries_for(connector)
          specs = specs_for(connector)
          waypoint_count = waypoint_pairs(connector).size
          specs.filter_map do |spec|
            next nil if suppress_arrow?(spec, connector)

            body = render_shape(spec)
            next nil unless body

            Entry.new(style_key: style_key_for(spec),
                      body: body,
                      anchor: anchor_for(spec),
                      connector_waypoint_count: waypoint_count)
          end
        end

        # Suppress arrow markers when:
        # 1. The diagram is an Object diagram (instance links).
        # 2. The connector is an unidirectional Association with
        #    significant waypoint deviation from a straight line
        #    (> 3px). EA treats connectors with small deviations as
        #    straight (WITH arrow); large deviations are orthogonal/
        #    tree-routed (NO arrow). Bidirectional associations always
        #    show arrows at both ends regardless of routing.
        BEND_DEVIATION_THRESHOLD = 3

        def suppress_arrow?(spec, connector)
          return false unless spec.shape == :arrow
          return true if object_diagram? && association?(connector)
          return false if connector.direction == "Bi-Directional"
          return true if horizontal_tree_routed?(connector)

          false
        end

        # A "horizontal tree-routed" connector has its source and
        # target endpoints at the SAME y-coordinate with interior
        # waypoints deviating above and below — the classic EA tree
        # routing pattern where multiple connectors fan out from a
        # shared parent at the same height. These don't render arrow
        # markers in basic.qea Classes diagrams. This check is
        # deliberately narrow to avoid suppressing arrows on plateau
        # connectors where source and target are at different heights.
        def horizontal_tree_routed?(connector)
          return false unless association?(connector)
          return false if object_diagram?

          points = waypoint_pairs(connector)
          return false if points.size < 4

          source = points.first
          target = points.last
          return false unless source[1] == target[1]

          max_bend_deviation(connector) > BEND_DEVIATION_THRESHOLD
        end

        def tree_routed_association?(connector)
          return false unless association?(connector)
          return false if object_diagram?
          return false if connector.direction == "Bi-Directional"

          # Only apply the tree-routed heuristic to connectors with
          # 4+ waypoints AND significant bend deviation. 3-waypoint
          # connectors with a single bend are too common on plateau
          # to suppress reliably.
          points = waypoint_pairs(connector)
          return false if points.size < 4

          max_bend_deviation(connector) > BEND_DEVIATION_THRESHOLD
        end

        def max_bend_deviation(connector)
          points = waypoint_pairs(connector)
          return 0 if points.size < 3

          source = points.first
          target = points.last
          interior = points[1..-2]
          interior.map { |p| perpendicular_distance(p, source, target) }.max || 0
        end

        def perpendicular_distance(point, line_start, line_end)
          px, py = point
          x1, y1 = line_start
          x2, y2 = line_end
          dx = x2 - x1
          dy = y2 - y1
          length_sq = dx * dx + dy * dy
          return 0 if length_sq.zero?

          ((dy * px - dx * py + x2 * y1 - y2 * x1).abs / Math.sqrt(length_sq)).round
        end

        def association?(connector)
          effective_type(connector) == "Association"
        end

        def object_diagram?
          diagram.diagram_type == "Object"
        end

        # Rounded [x, y] of the marker's tip (anchor) in canvas
        # coordinates. Used for deduplication.
        def anchor_for(spec)
          tx, ty = translate_point(spec.anchor)
          [tx.round, ty.round]
        end

        def style_key_for(spec)
          SHAPE_REGISTRY.dig(spec.shape, :style_key)
        end

        # Rounded [x, y] of the marker's tip (anchor) in canvas
        # coordinates. Used for deduplication.
        def anchor_for(spec)
          tx, ty = translate_point(spec.anchor)
          [tx.round, ty.round]
        end

        def render_shape(spec)
          entry = SHAPE_REGISTRY[spec.shape]
          return nil unless entry

          entry[:render].call(self, spec.anchor, spec.base)
        end

        # Plus marker: two crossed line segments at the anchor.
        # EA encodes as one <path> with two sub-paths:
        #   M cx cy-8 L cx cy+8    (vertical arm)
        #   M cx+8 cy L cx-8 cy    (horizontal arm)
        def plus_path(anchor)
          cx, cy = translate_point(anchor)
          cx_str = Canvas.coord(cx)
          cy_str = Canvas.coord(cy)
          up = Canvas.coord(cy - Marker::Plus::ARM_LENGTH)
          down = Canvas.coord(cy + Marker::Plus::ARM_LENGTH)
          left = Canvas.coord(cx - Marker::Plus::ARM_LENGTH)
          right = Canvas.coord(cx + Marker::Plus::ARM_LENGTH)
          d = "M #{cx_str} #{up} L #{cx_str} #{down} M #{right} #{cy_str} L #{left} #{cy_str}"
          %(<path d="#{d}" shape-rendering="auto"/>)
        end

        def specs_for(connector)
          points = waypoint_pairs(connector)
          return [] if points.size < 2

          source = points.first
          target = points.last
          before_target = points[-2] || source
          after_source = points[1] || target
          Marker::Registry.specs_for(connector,
                                     effective_type(connector),
                                     source, target,
                                     before_target, after_source,
                                     relationship: relationship_for(connector))
        end

        def effective_type(connector)
          return connector.connector_type if connector.connector_type

          rel = relationship_for(connector)
          return "Association" unless rel

          # Use the polymorphic kind field rather than class-name
          # inspection - subclasses set `relationship_kind` at the
          # model level (e.g. Association → "association", which we
          # then capitalize to match EA's Connector_Type).
          kind = rel.relationship_kind || "association"
          kind.capitalize
        end

        def relationship_for(connector)
          return nil unless connector.relationship_ref && model_index

          model_index[connector.relationship_ref]
        end

        def diamond_polygon(tip, base)
          tx, ty = translate_point(tip)
          bx, by = translate_point(base)
          ux, uy = unit_vector(tx, ty, bx, by)
          return nil unless ux

          right_x = tx - ux * DIAMOND_HALF_H + (-uy) * DIAMOND_HALF_W
          right_y = ty - uy * DIAMOND_HALF_H + ux * DIAMOND_HALF_W
          back_x = tx - ux * (DIAMOND_HALF_H * 2)
          back_y = ty - uy * (DIAMOND_HALF_H * 2)
          left_x = tx - ux * DIAMOND_HALF_H - (-uy) * DIAMOND_HALF_W
          left_y = ty - uy * DIAMOND_HALF_H - ux * DIAMOND_HALF_W
          pts = [
            Canvas.coord(tx), Canvas.coord(ty),
            Canvas.coord(right_x), Canvas.coord(right_y),
            Canvas.coord(back_x), Canvas.coord(back_y),
            Canvas.coord(left_x), Canvas.coord(left_y)
          ].join(" ")
          %(<polygon points="#{pts}" shape-rendering="auto"   style="fill-rule:evenodd;"/>)
        end

        def triangle_polygon(tip, base)
          tx, ty = translate_point(tip)
          bx, by = translate_point(base)
          ux, uy = unit_vector(tx, ty, bx, by)
          return nil unless ux

          back_x = tx - ux * TRI_HEIGHT
          back_y = ty - uy * TRI_HEIGHT
          w1_x = back_x + (-uy) * TRI_HALF_BASE
          w1_y = back_y + ux * TRI_HALF_BASE
          w2_x = back_x - (-uy) * TRI_HALF_BASE
          w2_y = back_y - ux * TRI_HALF_BASE
          pts = [
            Canvas.coord(tx), Canvas.coord(ty),
            Canvas.coord(w1_x), Canvas.coord(w1_y),
            Canvas.coord(w2_x), Canvas.coord(w2_y)
          ].join(" ")
          %(<polygon points="#{pts}" shape-rendering="auto"   style="fill-rule:evenodd;"/>)
        end

        def arrow_path(tip, base)
          tx, ty = translate_point(tip)
          bx, by = translate_point(base)
          ux, uy = unit_vector(tx, ty, bx, by)
          return nil unless ux

          back_x = tx - ux * ARROW_HEIGHT
          back_y = ty - uy * ARROW_HEIGHT
          w1_x = back_x + (-uy) * ARROW_HALF_BASE
          w1_y = back_y + ux * ARROW_HALF_BASE
          w2_x = back_x - (-uy) * ARROW_HALF_BASE
          w2_y = back_y - ux * ARROW_HALF_BASE
          d = "M #{Canvas.coord(w1_x)} #{Canvas.coord(w1_y)} L #{Canvas.coord(tx)} #{Canvas.coord(ty)} L #{Canvas.coord(w2_x)} #{Canvas.coord(w2_y)}"
          %(<path d="#{d}" shape-rendering="auto"/>)
        end

        # «import» source-end marker: a small closed trapezoid that
        # visually represents the imported package. Shape is a 4-point
        # polygon: top edge shorter than bottom edge, centered on the
        # anchor point.
        PACKAGE_ANCHOR_W = 5
        PACKAGE_ANCHOR_H_TOP = 3
        PACKAGE_ANCHOR_H_BOTTOM = 4

        def package_anchor_path(tip, base)
          tx, ty = translate_point(tip)
          bx, by = translate_point(base)
          ux, uy = unit_vector(tx, ty, bx, by)
          return nil unless ux

          back_x = tx - ux * PACKAGE_ANCHOR_H_BOTTOM
          back_y = ty - uy * PACKAGE_ANCHOR_H_BOTTOM
          tl_x = tx - ux * PACKAGE_ANCHOR_H_TOP + (-uy) * PACKAGE_ANCHOR_W
          tl_y = ty - uy * PACKAGE_ANCHOR_H_TOP + ux * PACKAGE_ANCHOR_W
          tr_x = tx - ux * PACKAGE_ANCHOR_H_TOP - (-uy) * PACKAGE_ANCHOR_W
          tr_y = ty - uy * PACKAGE_ANCHOR_H_TOP - ux * PACKAGE_ANCHOR_W
          bl_x = back_x + (-uy) * (PACKAGE_ANCHOR_W + 1)
          bl_y = back_y + ux * (PACKAGE_ANCHOR_W + 1)
          br_x = back_x - (-uy) * (PACKAGE_ANCHOR_W + 1)
          br_y = back_y - ux * (PACKAGE_ANCHOR_W + 1)
          d = "M #{Canvas.coord(tl_x)} #{Canvas.coord(tl_y)} " \
              "L #{Canvas.coord(tr_x)} #{Canvas.coord(tr_y)} " \
              "L #{Canvas.coord(br_x)} #{Canvas.coord(br_y)} " \
              "L #{Canvas.coord(bl_x)} #{Canvas.coord(bl_y)} " \
              "L #{Canvas.coord(tl_x)} #{Canvas.coord(tl_y)} Z"
          %(<path d="#{d}" shape-rendering="auto"/>)
        end

        def unit_vector(tx, ty, bx, by)
          dx = tx - bx
          dy = ty - by
          len = Math.sqrt(dx * dx + dy * dy)
          return nil if len.zero?

          [dx / len, dy / len]
        end
        public :diamond_polygon, :triangle_polygon, :plus_path,
               :arrow_path, :package_anchor_path

        def translate_point(p)
          return p unless @canvas

          [@canvas.translate_x(p[0]), @canvas.translate_y(p[1])]
        end

        def waypoint_pairs(connector)
          (connector.waypoints || []).filter_map do |w|
            next unless w.position

            [w.position.x, w.position.y]
          end
        end
      end
    end
  end
end
