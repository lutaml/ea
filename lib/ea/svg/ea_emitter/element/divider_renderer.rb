# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the horizontal divider path between header and
        # attribute compartments.
        class DividerRenderer
          def self.render(bounds, y:, stroke:, stroke_width:)
            %(<g style="stroke-width:#{stroke_width};stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:0.00; stroke:#{stroke}; stroke-opacity:1.00">\n  <path d="M #{Canvas.coord(bounds.x)} #{Canvas.coord(y)} L #{Canvas.coord(bounds.x + bounds.width)} #{Canvas.coord(y)}" shape-rendering="auto"/>\n</g>)
          end
        end
      end
    end
  end
end
