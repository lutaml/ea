# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the shape `<g>` for a Package element: a rectangular
        # body polygon plus a "tab" polygon on top. EA renders every
        # Package as this folder-like silhouette regardless of diagram
        # type.
        #
        # Layout (element bounds cover tab + body together):
        #
        #   ┌───┐
        #   │tab│   ← top TAB_HEIGHT_SINGLE rows ABOVE element bounds;
        #   │   │     when a stereotype is present, the tab grows to
        #   └───┴──────────┐  TAB_HEIGHT_DOUBLE rows and extends INTO
        #   │               │   the bounds; the name renders bold,
        #   │     body      │   left-aligned. The body always starts
        #   │               │   where the tab ends.
        #   └───────────────┘
        #
        class PackageShapeRenderer
          TAB_HEIGHT_SINGLE = 20
          TAB_HEIGHT_DOUBLE = 36
          TAB_LABEL_PADDING = 10
          TAB_LABEL_X_OFFSET = 5
          TAB_LABEL_Y_OFFSET = 13
          TAB_LINE_OFFSET = 13
          DEFAULT_TAB_WIDTH = 105

          def self.render(bounds, fill:, stroke:, stroke_width:, label: nil,
                          stereotype: nil, family: "Carlito", size: 7,
                          size_unit: "pt", text_fill: "#000000")
            new(bounds, fill, stroke, stroke_width, label, stereotype,
                family, size, size_unit, text_fill).to_svg
          end

          def initialize(bounds, fill, stroke, stroke_width, label,
                         stereotype, family, size, size_unit, text_fill)
            @bounds = bounds
            @fill = fill
            @stroke = stroke
            @stroke_width = stroke_width
            @label = label
            @stereotype = stereotype
            @family = family
            @size = size
            @size_unit = size_unit
            @text_fill = text_fill
          end

          def to_svg
            parts = ["  #{body_polygon}", "  #{tab_polygon}"]
            parts += header_text_blocks if has_label?
            %(<g style="#{group_style}">\n#{parts.join("\n")}\n</g>)
          end

          private

          attr_reader :bounds, :fill, :stroke, :stroke_width, :label,
                      :stereotype, :family, :size, :size_unit, :text_fill

          def has_label?
            label && !label.empty?
          end

          def has_stereotype?
            stereotype && !stereotype.empty?
          end

          def group_style
            "stroke-width:#{stroke_width};stroke-linecap:round;stroke-linejoin:bevel; " \
              "fill:#{fill};fill-opacity:1.00; stroke:#{stroke}; stroke-opacity:1.00"
          end

          def body_polygon
            pts = body_points.map { |x, y| "#{Canvas.coord(x)} #{Canvas.coord(y)}" }.join(" ")
            %(<polygon points="#{pts}" shape-rendering="auto"   style="fill-rule:evenodd;"/>)
          end

          def tab_polygon
            pts = tab_points.map { |x, y| "#{Canvas.coord(x)} #{Canvas.coord(y)}" }.join(" ")
            %(<polygon points="#{pts}" shape-rendering="auto"   style="fill-rule:evenodd;"/>)
          end

          def header_text_blocks
            blocks = []
            if has_stereotype?
              blocks << "  #{text_at(label_x, stereotype_y, "«#{stereotype}»", weight: 0)}"
              blocks << "  #{text_at(label_x, name_y, label, weight: 700)}"
            else
              blocks << "  #{text_at(label_x, name_y_single, label, weight: 700)}"
            end
            blocks
          end

          def text_at(x, y, content, weight:)
            TextRenderer.new(content: content,
                              x: x, y: y,
                              family: family, size: size, size_unit: size_unit,
                              weight: weight, fill: text_fill,
                              text_length: content.length * 6).to_svg
          end

          def label_x
            bounds.x + TAB_LABEL_X_OFFSET
          end

          # Stereotype line baseline: 13px below the tab top.
          def stereotype_y
            tab_top_y + TAB_LABEL_Y_OFFSET
          end

          # Name baseline when stereotype is also rendered: 26px below
          # the tab top (one line below the stereotype).
          def name_y
            tab_top_y + TAB_LABEL_Y_OFFSET + TAB_LINE_OFFSET
          end

          # Name baseline when only the name renders (no stereotype):
          # 13px below the tab top.
          def name_y_single
            tab_top_y + TAB_LABEL_Y_OFFSET
          end

          # Tab anchored 20px above the bounds top — matches EA's
          # folder silhouette regardless of whether the tab holds one
          # line or two.
          def tab_top_y
            bounds.y - TAB_HEIGHT_SINGLE
          end

          def tab_height
            has_stereotype? ? TAB_HEIGHT_DOUBLE : TAB_HEIGHT_SINGLE
          end

          def body_points
            x = bounds.x
            y = tab_top_y + tab_height
            w = bounds.width
            h = body_height(y)
            [
              [x, y],
              [x + w, y],
              [x + w, y + h],
              [x, y + h],
              [x, y]
            ]
          end

          # Body extends from tab.bottom to (bounds.bottom - 20px
          # bottom margin). Total body height = bounds.height -
          # tab_height (because tab takes (tab_height - 20) from the
          # top of the bounds plus 20 above the bounds).
          def body_height(body_top)
            bounds.y + bounds.height - TAB_HEIGHT_SINGLE - body_top
          end

          def tab_points
            x = bounds.x
            y = tab_top_y
            w = tab_width
            h = tab_height
            [
              [x, y],
              [x + w, y],
              [x + w, y + h],
              [x, y + h],
              [x, y]
            ]
          end

          def tab_width
            DEFAULT_TAB_WIDTH
          end
        end
      end
    end
  end
end
