# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the small "folded paper" classifier-type icon at the
        # top-right corner of an element box. EA renders this when
        # the element's style does NOT set HideIcon=1.
        #
        # The icon is two `<path>` elements:
        #
        #   1. Outer outline (closed): a 9×11 rectangle with the
        #      top-right corner "folded" (a 3×4 triangular cut).
        #   2. Folded corner detail (open): the L-shape indicating
        #      the fold.
        #
        # Style:
        #   - Outer:    fill=#DCF8F0, stroke=#577AC1
        #   - Corner:   fill=transparent, stroke=#577AC1
        #   - stroke-width=1, stroke-linecap=square, linejoin=bevel
        class IconRenderer
          OUTER_FILL = "#DCF8F0"
          OUTER_STROKE = "#577AC1"
          CORNER_FILL = "##{0.to_s.rjust(6, '0')}" # transparent black
          WIDTH = 9
          HEIGHT = 11
          FOLD_WIDTH = 3
          FOLD_HEIGHT = 4
          X_INSET = 13
          Y_OFFSET = 3

          attr_reader :bounds, :canvas

          def initialize(bounds:, canvas: nil)
            @bounds = bounds
            @canvas = canvas
          end

          def self.render(bounds:, canvas: nil, family: nil, size: nil)
            new(bounds: bounds, canvas: canvas).to_svg
          end

          # Returns the two `<path>` elements joined as a single
          # String. Returns "" if bounds is nil.
          def to_svg
            return "" unless bounds

            "#{outer_path}\n#{corner_path}"
          end

          private

          def outer_path
            x, y = top_left
            right = x + WIDTH
            bottom = y + HEIGHT
            fold_x = right - FOLD_WIDTH
            fold_y = y + FOLD_HEIGHT
            d = "M #{coord(x)} #{coord(y)} " \
                "L #{coord(fold_x)} #{coord(y)} " \
                "L #{coord(right)} #{coord(fold_y)} " \
                "L #{coord(right)} #{coord(bottom)} " \
                "L #{coord(x)} #{coord(bottom)} " \
                "L #{coord(x)} #{coord(y)} Z"
            %(<g style="#{outer_style}">\n  <path d="#{d}" shape-rendering="auto"/>\n</g>)
          end

          def corner_path
            x, y = top_left
            right = x + WIDTH
            fold_x = right - FOLD_WIDTH
            fold_y = y + FOLD_HEIGHT
            d = "M #{coord(fold_x)} #{coord(y)} " \
                "L #{coord(fold_x)} #{coord(fold_y)} " \
                "L #{coord(right)} #{coord(fold_y)}"
            %(<g style="#{corner_style}">\n  <path d="#{d}" shape-rendering="auto"/>\n</g>)
          end

          def outer_style
            "stroke-width:1;stroke-linecap:square;stroke-linejoin:bevel; " \
              "fill:#{OUTER_FILL};fill-opacity:1.00; stroke:#{OUTER_STROKE}; stroke-opacity:1.00"
          end

          def corner_style
            "stroke-width:1;stroke-linecap:square;stroke-linejoin:bevel; " \
              "fill:#000000;fill-opacity:0.00; stroke:#{OUTER_STROKE}; stroke-opacity:1.00"
          end

          # Top-left of the icon: x = bounds.right - X_INSET,
          # y = bounds.top + Y_OFFSET.
          def top_left
            tx = bounds.x + bounds.width - X_INSET
            ty = bounds.y + Y_OFFSET
            if canvas
              [canvas.translate_x(tx), canvas.translate_y(ty)]
            else
              [tx, ty]
            end
          end

          def coord(value)
            Ea::Svg::EaEmitter::Canvas.coord(value)
          end
        end
      end
    end
  end
end
