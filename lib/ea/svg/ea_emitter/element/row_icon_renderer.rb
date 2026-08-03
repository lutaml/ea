# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the small per-row icon EA draws next to each entry in
        # a package-contents body (or a classifier's attribute row when
        # ShowIcons is on). The icon's silhouette encodes the child's
        # classifier type:
        #
        #   * Enumeration: a 12x13 green rect with a list-style glyph
        #     (single rect + seven paths).
        #   * Sub-Package: a small 13x9 folder rect (no extra paths).
        #   * Other Classifier kinds (Klass/DataType/Primitive/etc.):
        #     an 11x14 "folded paper" silhouette with white top + a
        #     midline + four text-rule lines (two rects + seven paths).
        #
        # The renderer returns the SVG body as a String. The caller
        # wraps it in the appropriate parent `<g>`.
        class RowIconRenderer
          OUTER_FILL = "#FEFAF5"
          INNER_FILL = "#FFFFFF"
          ENUMERATION_FILL = "#E6FFE1"
          PACKAGE_FILL = "#FEFAF5"
          STROKE = "#577AC1"
          RED_STROKE = "#EF8585"
          GRAY_STROKE = "#4D4D4D"
          ENUM_RED_STROKE = "#7D0000"

          WIDTH = 11
          HEIGHT = 14
          INNER_HEIGHT = 4
          ENUM_WIDTH = 12
          ENUM_HEIGHT = 13
          PACKAGE_WIDTH = 13
          PACKAGE_HEIGHT = 9

          # Default icon path specs: each entry is [x1, y1, x2, y2, stroke].
          # Coordinates are relative to the icon's top-left corner.
          DEFAULT_PATHS = [
            [0, 7, 10, 7, STROKE],
            [2, 5, 6, 5, RED_STROKE],
            [8, 5, 9, 5, RED_STROKE],
            [2, 9, 6, 9, GRAY_STROKE],
            [8, 9, 9, 9, GRAY_STROKE],
            [2, 11, 6, 11, GRAY_STROKE],
            [8, 11, 9, 11, GRAY_STROKE]
          ].freeze

          # Enumeration icon path specs. First entry is the red path
          # drawn as a closed "L" shape; the rest are horizontal lines.
          ENUM_PATHS = [
            [:curve, 5, 2, 2, 2, 2, 6, 5, 6, ENUM_RED_STROKE],
            [:line, 2, 4, 4, 4, ENUM_RED_STROKE],
            [:line, 7, 2, 9, 2, STROKE],
            [:line, 7, 4, 9, 4, STROKE],
            [:line, 7, 6, 9, 6, STROKE],
            [:line, 0, 8, 11, 8, STROKE],
            [:line, 2, 10, 9, 10, STROKE]
          ].freeze

          # Returns the SVG body String for the icon at (x_pos, y_pos).
          # `kind` is one of :enumeration, :package, or :default.
          def self.render(x_pos:, y_pos:, kind: :default)
            case kind
            when :enumeration then enumeration_icon(x_pos, y_pos)
            when :package then package_icon(x_pos, y_pos)
            else default_icon(x_pos, y_pos)
            end
          end

          class << self
            private

            def package_icon(x_pos, y_pos)
              svg_rect(x_pos: x_pos, y_pos: y_pos,
                       width: PACKAGE_WIDTH, height: PACKAGE_HEIGHT,
                       fill: PACKAGE_FILL)
            end

            def default_icon(x_pos, y_pos)
              rects = default_rects(x_pos, y_pos)
              paths = DEFAULT_PATHS.map do |(dx1, dy1, dx2, dy2, stroke)|
                svg_line(x_pos + dx1, y_pos + dy1, x_pos + dx2, y_pos + dy2,
                         stroke)
              end
              (rects + paths).join("\n")
            end

            def default_rects(x_pos, y_pos)
              [
                svg_rect(x_pos: x_pos, y_pos: y_pos, width: WIDTH, height: HEIGHT,
                         fill: OUTER_FILL),
                svg_rect(x_pos: x_pos, y_pos: y_pos, width: WIDTH, height: INNER_HEIGHT,
                         fill: INNER_FILL)
              ]
            end

            def enumeration_icon(x_pos, y_pos)
              rect = svg_rect(x_pos: x_pos, y_pos: y_pos,
                              width: ENUM_WIDTH, height: ENUM_HEIGHT,
                              fill: ENUMERATION_FILL)
              paths = ENUM_PATHS.map do |spec|
                svg_for_spec(spec, x_pos, y_pos)
              end
              ([rect] + paths).join("\n")
            end

            def svg_for_spec(spec, x_pos, y_pos)
              return svg_curve_spec(spec, x_pos, y_pos) if spec.first == :curve

              svg_line_spec(spec, x_pos, y_pos)
            end

            def svg_curve_spec(spec, x_pos, y_pos)
              _, dx1, dy1, dx2, dy2, dx3, dy3, stroke = spec
              points = [x_pos + dx1, y_pos + dy1, x_pos + dx2, y_pos + dy2,
                        x_pos + dx3, y_pos + dy3]
              svg_curve(points, stroke)
            end

            def svg_line_spec(spec, x_pos, y_pos)
              _, dx1, dy1, dx2, dy2, stroke = spec
              svg_line(x_pos + dx1, y_pos + dy1, x_pos + dx2, y_pos + dy2,
                       stroke)
            end

            def svg_rect(x_pos:, y_pos:, width:, height:, fill:)
              style = "fill:#{fill}; stroke:#{STROKE};"
              %(<rect x="#{x_pos}" y="#{y_pos}" width="#{width}" ) \
                "height=\"#{height}\" rx=\"0.00\" shape-rendering=\"auto\" " \
                "style=\"#{style}\"/>"
            end

            def svg_line(x_start, y_start, x_end, y_end, stroke)
              svg_path("M #{x_start} #{y_start} L #{x_end} #{y_end}", stroke)
            end

            def svg_curve(points, stroke)
              x_start, y_start, x_mid, y_mid, x_end, y_end = points
              d = "M #{x_start} #{y_start} L #{x_mid} #{y_mid} " \
                  "L #{x_end} #{y_end}"
              svg_path(d, stroke)
            end

            def svg_path(path_data, stroke)
              style = "fill:none; stroke:#{stroke};"
              %(<path d="#{path_data}" shape-rendering="auto" style="#{style}"/>)
            end
          end
        end
      end
    end
  end
end
