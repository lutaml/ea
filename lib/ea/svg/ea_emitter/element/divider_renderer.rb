# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the horizontal divider path between header and
        # attribute compartments. EA draws the divider from the box
        # left edge to one pixel INSIDE the right edge (corpus-
        # verified: right end = box_right - 1 in 190 of 237
        # identity-matched dividers).
        class DividerRenderer
          def self.render(bounds, y:, stroke:, stroke_width:)
            %(<g style="stroke-width:#{stroke_width};stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:0.00; stroke:#{stroke}; stroke-opacity:1.00">\n  <path d="M #{Canvas.coord(bounds.x)} #{Canvas.coord(y)} L #{Canvas.coord(bounds.x + bounds.width - 1)} #{Canvas.coord(y)}" shape-rendering="auto"/>\n</g>)
          end
        end
      end
    end
  end
end
