# frozen_string_literal: true

require "nokogiri"

module Ea
  module Svg
    module Parity
      # Normalizes an EA-style SVG (ours or EA's own export — both use
      # the same writer conventions) into a flat list of primitives,
      # then reports itemized differences: missing/extra/moved texts,
      # wrong fonts, shape geometry deltas.
      #
      # Primitives inherit fill/stroke from their wrapping <g style>
      # since both writers emit one primitive per group.
      class Differ
        EPSILON = 0.51 # sub-pixel jitter is noise; EA writes 2 decimals
        MATCH_DISTANCE = 6.0 # max centroid distance for shape pairing

        attr_reader :ours, :reference

        def initialize(ours:, reference:)
          @ours = parse(ours)
          @reference = parse(reference)
          @shift = dominant_shift
        end

        # Extracts the primitives consumed by both comparison reports.
        class PrimitiveParser
          def parse(svg)
            Nokogiri::XML(svg).css("g").flat_map do |group|
              group.element_children.filter_map { |node| primitive(node, group["style"] || "") }
            end
          end

          def primitive(node, style)
            case node.name
            when "text" then text_primitive(node, style)
            when "rect" then rect_primitive(node, style)
            when "polygon" then points_primitive(:polygon, node["points"], style)
            when "line" then points_primitive(:line, line_points(node), style)
            when "path" then path_primitive(node, style)
            end
          end
          private :primitive

          def line_points(node)
            %w[x1 y1 x2 y2].map { |key| node[key] }.join(" ")
          end
          private :line_points

          def text_primitive(node, g_style)
            style = node["style"] || ""
            {
              kind: :text,
              x: float(node["x"]), y: float(node["y"]),
              content: node.text.strip,
              **text_style(style),
              fill: style[/[^-]fill:([^;]+)/, 1] || g_style[/fill:([^;]+)/, 1]
            }
          end
          private :text_primitive

          def text_style(style)
            {
              family: style[/font-family:([^;]+)/, 1],
              size: style[/font-size:([^;]+)/, 1],
              weight: normalize_weight(style[/font-weight:([^;]+)/, 1]),
              style: style[/font-style:([^;]+)/, 1]
            }
          end
          private :text_style

          def rect_primitive(node, g_style)
            {
              kind: :rect,
              x: float(node["x"]), y: float(node["y"]),
              width: float(node["width"]), height: float(node["height"]),
              centroid: rect_centroid(node),
              fill: g_style[/fill:([^;]+)/, 1],
              stroke: g_style[/stroke:([^;]+)/, 1]
            }
          end
          private :rect_primitive

          def rect_centroid(node)
            x = float(node["x"])
            y = float(node["y"])
            return [0.0, 0.0] if x.nil? || y.nil?

            [x + float(node["width"]).to_f / 2, y + float(node["height"]).to_f / 2]
          end
          private :rect_centroid

          def path_primitive(node, g_style)
            points = (node["d"] || "").scan(/-?\d+(?:\.\d+)?/).each_slice(2)
                     .map { |(x, y)| [x.to_f, y.to_f] }
            {
              kind: :path, points: points,
              centroid: centroid(points), closed: node["d"].to_s.match?(/[zZ]/),
              stroke: g_style[/stroke:([^;]+)/, 1]
            }
          end
          private :path_primitive

          def points_primitive(kind, points_attr, g_style)
            points = (points_attr || "").scan(/-?\d+(?:\.\d+)?/).each_slice(2)
                     .map { |(x, y)| [x.to_f, y.to_f] }
            {
              kind: kind, points: points, centroid: centroid(points),
              stroke: g_style[/stroke:([^;]+)/, 1]
            }
          end
          private :points_primitive

          def centroid(points)
            return [0.0, 0.0] if points.nil? || points.empty?

            xs = points.map(&:first)
            ys = points.map(&:last)
            [xs.sum / points.size, ys.sum / points.size]
          end
          private :centroid

          def float(value)
            value&.to_f
          end
          private :float

          def normalize_weight(raw)
            return "400" if raw.nil? || raw == "0"

            raw
          end
          private :normalize_weight
        end
        private_constant :PrimitiveParser

        # Matches content and measures text/font drift after canvas alignment.
        module TextComparison
          # EA crops each published image to its own content bounds, so
          # the two canvases differ by a per-diagram translation. Estimate
          # it as the modal delta over content-matched texts and subtract
          # it before comparing positions.
          def dominant_shift
            references = texts_by_content
            deltas = our_texts.filter_map { |ours| text_shift(ours, references[ours[:content]]) }
            return [0.0, 0.0] if deltas.empty?

            deltas.tally.max_by { |_, count| count }.first.map(&:to_f)
          end
          private :dominant_shift

          # Texts pair on identical content; positions, family, size and
          # weight are then compared directly.
          def text_deltas
            references = texts_by_content
            deltas = Hash.new { |hash, key| hash[key] = [] }
            our_texts.each { |ours| compare_text(ours, references[ours[:content]], deltas) }
            deltas[:missing_text].concat(references.values.flatten)
            deltas
          end

          def our_texts
            @ours.select { |primitive| primitive[:kind] == :text }
          end
          private :our_texts

          def texts_by_content
            @reference.select { |primitive| primitive[:kind] == :text }.group_by { |primitive| primitive[:content] }
          end
          private :texts_by_content

          def text_shift(ours, candidates)
            reference = candidates&.min_by { |candidate| distance(ours, candidate) }
            return unless reference

            [(reference[:x] - ours[:x]).round, (reference[:y] - ours[:y]).round]
          end
          private :text_shift

          def compare_text(ours, candidates, deltas)
            reference = candidates&.min_by { |candidate| distance(ours, candidate) }
            return deltas[:extra_text] << ours unless reference

            candidates.delete(reference)
            deltas[:moved_text] << ours if moved?(ours, reference)
            compare_font(ours, reference, deltas)
          end
          private :compare_text

          def compare_font(ours, reference, deltas)
            { family: :wrong_font, size: :wrong_size, weight: :wrong_weight }.each do |key, mismatch|
              next if font_value(ours, key) == font_value(reference, key)

              deltas[mismatch] << [ours, reference]
            end
          end
          private :compare_font

          def font_value(primitive, key)
            key == :weight ? normalize_weight(primitive[key]) : primitive[key]
          end
          private :font_value

          def moved?(ours, ref)
            ((ours[:x] + @shift[0]) - ref[:x]).abs > EPSILON ||
              ((ours[:y] + @shift[1]) - ref[:y]).abs > EPSILON
          end
          private :moved?

          def distance(ours, reference)
            Math.hypot(ours[:x] - reference[:x], ours[:y] - reference[:y])
          end
          private :distance

          def normalize_weight(raw)
            return "400" if raw.nil? || raw == "0"

            raw
          end
          private :normalize_weight
        end
        private_constant :TextComparison
        include TextComparison

        # Endpoint distances are Euclidean distances after canvas alignment. Polygon tips
        # correspond by vertex index, as in shape_deltas. An unpaired arrowhead
        # has infinite drift; correctly placed endpoints and tips have zero.
        module ConnectorComparison
          def connector_deltas
            heads = shape_pairs(arrowheads(@reference), arrowheads(@ours))
            connector_pairs.map do |ours, ref|
              connector_delta(ours, ref).merge(arrowhead_deltas: arrowhead_deltas(ours, ref, heads))
            end
          end

          def connector_delta(ours, ref)
            {
              kind: ours[:kind], ours: ours, reference: ref,
              source_delta: endpoint_distance(ours[:points].first, ref[:points].first),
              target_delta: endpoint_distance(ours[:points].last, ref[:points].last)
            }
          end
          private :connector_delta

          def connectors(primitives)
            primitives.select do |primitive|
              %i[path line].include?(primitive[:kind]) && !primitive[:closed] &&
                primitive[:points].size >= 2 && !open_arrowhead?(primitive)
            end
          end
          private :connectors

          # Preserve a match when one dock moves far enough to change the
          # centroid. Choose the smallest total endpoint drift first, so a
          # shared target cannot steal another connector's exact match.
          def connector_pairs
            candidates = connectors(@ours).product(connectors(@reference))
            candidates.sort_by! { |ours, ref| connector_distance(ours, ref) }
            used = {}.compare_by_identity
            candidates.select do |ours, ref|
              next false if used[ours] || used[ref] || !connector_distance(ours, ref).finite?

              used[ours] = used[ref] = true
            end
          end
          private :connector_pairs

          def connector_distance(ours, ref)
            return Float::INFINITY unless ours[:kind] == ref[:kind]

            drifts = connector_delta(ours, ref).values_at(:source_delta, :target_delta)
            return drifts.sum if drifts.min <= MATCH_DISTANCE
            return drifts.sum if shape_distance(shift_primitive(ours), ref) <= MATCH_DISTANCE

            Float::INFINITY
          end
          private :connector_distance

          def endpoint_distance(ours, ref)
            return Float::INFINITY unless ours && ref

            Math.hypot(ours[0] + @shift[0] - ref[0], ours[1] + @shift[1] - ref[1])
          end
          private :endpoint_distance
        end
        private_constant :ConnectorComparison
        include ConnectorComparison

        # EA emits triangle/diamond polygons and symmetric open V paths. The
        # latter have their tip at the middle vertex, rather than at an end.
        module ArrowheadComparison
          def arrowheads(primitives)
            primitives.select { |primitive| primitive[:kind] == :polygon || open_arrowhead?(primitive) }
          end
          private :arrowheads

          def open_arrowhead?(primitive)
            return false unless primitive[:kind] == :path && !primitive[:closed] && primitive[:points].size == 3

            symmetric_wings?(*primitive[:points])
          end
          private :open_arrowhead?

          def symmetric_wings?(first, tip, last)
            left = point_distance(first, tip)
            right = point_distance(last, tip)
            base = point_distance(first, last)
            # EA rounds each vertex to whole pixels, allowing up to sqrt(2)
            # error per wing. Ordinary right-angle bends are not arrowheads.
            (left - right).abs <= 2 * Math.sqrt(2) && base.positive? && base < [left, right].min
          end
          private :symmetric_wings?

          def point_distance(first, last)
            Math.hypot(first[0] - last[0], first[1] - last[1])
          end
          private :point_distance

          def arrowhead_deltas(ours, ref, heads)
            { source: 0, target: -1 }.filter_map do |name, index|
              pair = arrowhead_pair(ours[:points][index], ref[:points][index], heads)
              next unless pair

              our_head, ref_head, tip = pair
              { end: name, ours: our_head, reference: ref_head,
                tip_delta: endpoint_distance(our_head&.dig(:points, tip), ref_head&.dig(:points, tip)) }
            end
          end
          private :arrowhead_deltas

          def arrowhead_pair(our_point, ref_point, heads)
            if (attachment = touching_arrowhead(@reference, ref_point))
              ref, tip = attachment
              ours = heads.find { |_, candidate| candidate.equal?(ref) }&.first
            elsif (attachment = touching_arrowhead(@ours, our_point))
              ours, tip = attachment
              ref = heads.find { |candidate, _| candidate.equal?(ours) }&.last
            else
              return
            end

            [ours, ref, tip]
          end
          private :arrowhead_pair

          def touching_arrowhead(primitives, endpoint)
            vertices = arrowheads(primitives).flat_map do |head|
              indices = head[:kind] == :path ? [1] : head[:points].each_index
              indices.map { |index| [head, index] }
            end
            nearest = vertices.min_by { |polygon, index| vertex_distance(polygon, index, endpoint) }
            nearest if nearest && vertex_distance(*nearest, endpoint) <= EPSILON
          end
          private :touching_arrowhead

          def vertex_distance(polygon, index, endpoint)
            point = polygon[:points][index]
            Math.hypot(point[0] - endpoint[0], point[1] - endpoint[1])
          end
          private :vertex_distance
        end
        private_constant :ArrowheadComparison
        include ArrowheadComparison

        def parse(svg)
          PrimitiveParser.new.parse(svg)
        end
        private :parse

        # Shapes pair greedily by shift-corrected centroid distance
        # within the same kind. Geometry deltas do not affect these counts.
        def shape_summary
          our_count = @ours.count { |p| p[:kind] != :text }
          ref_shapes = @reference.reject { |p| p[:kind] == :text }
          matched = shape_pairs(ref_shapes).size

          {
            our_shapes: our_count, ref_shapes: ref_shapes.size + matched,
            matched: matched, missing: ref_shapes.size, extra: our_count - matched
          }
        end

        # Signed rectangle deltas are shifted ours minus reference.
        # Primitives retain their original coordinates; polygon vertices
        # correspond by index, with unequal counts reported as infinity.
        def shape_deltas
          shape_pairs.filter_map do |ours, ref|
            delta = case ours[:kind]
                    when :rect
                      rect_deltas(ours, ref)
                    when :polygon
                      { max_point_delta: max_point_delta(ours[:points], ref[:points]) }
                    end
            { kind: ours[:kind], ours: ours, reference: ref }.merge(delta) if delta
          end
        end

        def rect_deltas(ours, ref)
          {
            dx: dimension_delta(ours, ref, :x) + @shift[0],
            dy: dimension_delta(ours, ref, :y) + @shift[1],
            dwidth: dimension_delta(ours, ref, :width),
            dheight: dimension_delta(ours, ref, :height)
          }
        end
        private :rect_deltas

        def dimension_delta(ours, ref, key)
          ours[key].to_f - ref[key].to_f
        end
        private :dimension_delta

        def shape_pairs(ref_shapes = @reference.reject { |p| p[:kind] == :text },
                        our_shapes = @ours.reject { |p| p[:kind] == :text })
          our_shapes.filter_map do |ours|
            shifted = shift_primitive(ours)
            ref = ref_shapes.min_by { |c| shape_distance(shifted, c) }
            next unless ref && shape_distance(shifted, ref) <= MATCH_DISTANCE

            ref_shapes.delete(ref)
            [ours, ref]
          end
        end
        private :shape_pairs

        def max_point_delta(ours, ref)
          return Float::INFINITY unless ours.size == ref.size

          ours.zip(ref).map do |(x, y), (ref_x, ref_y)|
            Math.hypot(x + @shift[0] - ref_x, y + @shift[1] - ref_y)
          end.max || 0.0
        end
        private :max_point_delta

        def shift_primitive(primitive)
          if primitive[:centroid]
            primitive.merge(centroid: [primitive[:centroid][0] + @shift[0], primitive[:centroid][1] + @shift[1]])
          else
            primitive
          end
        end
        private :shift_primitive

        def shape_distance(ours, reference)
          return Float::INFINITY unless ours[:kind] == reference[:kind]
          return Float::INFINITY if ours[:centroid].nil? || reference[:centroid].nil?

          ax, ay = ours[:centroid]
          bx, by = reference[:centroid]
          Math.sqrt(((ax - bx).abs**2) + ((ay - by).abs**2))
        end
        private :shape_distance
      end
    end
  end
end
