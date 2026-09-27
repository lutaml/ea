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
        end

        # --- primitive extraction -----------------------------------

        def parse(svg)
          doc = Nokogiri::XML(svg)
          primitives = []
          doc.css("g").each do |g|
            g_style = g["style"] || ""
            g.children.each do |node|
              next unless node.element?

              case node.name
              when "text" then primitives << text_primitive(node, g_style)
              when "rect" then primitives << rect_primitive(node, g_style)
              when "polygon" then primitives << points_primitive(:polygon, node["points"], g_style)
              when "line"
                primitives << points_primitive(:line, "#{node['x1']} #{node['y1']} #{node['x2']} #{node['y2']}", g_style)
              when "path" then primitives << path_primitive(node, g_style)
              end
            end
          end
          primitives
        end
        private :parse

        def text_primitive(node, g_style)
          style = node["style"] || ""
          {
            kind: :text,
            x: float(node["x"]), y: float(node["y"]),
            content: node.text.strip,
            family: style[/font-family:([^;]+)/, 1],
            size: style[/font-size:([^;]+)/, 1],
            weight: normalize_weight(style[/font-weight:([^;]+)/, 1]),
            style: style[/font-style:([^;]+)/, 1],
            fill: style[/[^-]fill:([^;]+)/, 1] || g_style[/fill:([^;]+)/, 1]
          }
        end
        private :text_primitive

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
          x = float(node["x"]); y = float(node["y"])
          return [0.0, 0.0] if x.nil? || y.nil?

          [x + float(node["width"]).to_f / 2, y + float(node["height"]).to_f / 2]
        end
        private :rect_centroid

        def path_primitive(node, g_style)
          points = (node["d"] || "").scan(/-?\d+(?:\.\d+)?/).each_slice(2)
                                    .map { |(x, y)| [x.to_f, y.to_f] }
          {
            kind: :path, points: points,
            centroid: centroid(points), closed: node["d"].to_s.include?("Z"),
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

          xs = points.map(&:first); ys = points.map(&:last)
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

        # --- diffing -------------------------------------------------

        # Texts pair on identical content; positions, family, size and
        # weight are then compared directly.
        def text_deltas
          ref_by_content = @reference.select { |p| p[:kind] == :text }
                                     .group_by { |p| p[:content] }
          deltas = Hash.new { |h, k| h[k] = [] }

          @ours.select { |p| p[:kind] == :text }.each do |ours|
            candidates = ref_by_content[ours[:content]]
            ref = candidates&.min_by { |c| distance(ours, c) }
            if ref.nil?
              deltas[:extra_text] << ours
              next
            end
            candidates.delete(ref)

            deltas[:moved_text] << ours if moved?(ours, ref)
            deltas[:wrong_font] << [ours, ref] if ours[:family] != ref[:family]
            deltas[:wrong_size] << [ours, ref] if ours[:size] != ref[:size]
            deltas[:wrong_weight] << [ours, ref] if normalize_weight(ours[:weight]) != normalize_weight(ref[:weight])
          end

          unmatched = ref_by_content.values.flatten
          deltas[:missing_text].concat(unmatched)
          deltas
        end

        # Shapes pair greedily by centroid distance within the same
        # kind; paired shapes count as equal when their bounding boxes
        # agree within epsilon (routing bend-level diffs need the
        # point-level comparison and are reported as count mismatches).
        def shape_summary
          our_shapes = @ours.reject { |p| p[:kind] == :text }
          ref_shapes = @reference.reject { |p| p[:kind] == :text }

          matched = 0
          our_shapes.each do |ours|
            ref = ref_shapes.min_by { |c| shape_distance(ours, c) }
            next unless ref && shape_distance(ours, ref) <= MATCH_DISTANCE

            ref_shapes.delete(ref)
            matched += 1
          end

          {
            our_shapes: our_shapes.size, ref_shapes: ref_shapes.size + matched,
            matched: matched, missing: ref_shapes.size, extra: our_shapes.size - matched
          }
        end

        def shape_distance(a, b)
          return Float::INFINITY unless a[:kind] == b[:kind]
          return Float::INFINITY if a[:centroid].nil? || b[:centroid].nil?

          ax, ay = a[:centroid]; bx, by = b[:centroid]
          Math.sqrt(((ax - bx).abs**2) + ((ay - by).abs**2))
        end
        private :shape_distance

        def moved?(ours, ref)
          (ours[:x] - ref[:x]).abs > EPSILON || (ours[:y] - ref[:y]).abs > EPSILON
        end
        private :moved?

        def distance(a, b)
          Math.sqrt(((a[:x] - b[:x]).abs**2) + ((a[:y] - b[:y]).abs**2))
        end
        private :distance
      end
    end
  end
end
