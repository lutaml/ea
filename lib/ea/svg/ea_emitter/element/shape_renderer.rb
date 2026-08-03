# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the shape `<g>` containing a filled, stroked rect
        # for one diagram element box.
        class ShapeRenderer
          def self.render(bounds, fill:, stroke:, stroke_width:)
            %(<g style="stroke-width:#{stroke_width};stroke-linecap:round;stroke-linejoin:bevel; fill:#{fill};fill-opacity:1.00; stroke:#{stroke}; stroke-opacity:1.00">\n  <rect x="#{Canvas.coord(bounds.x)}" y="#{Canvas.coord(bounds.y)}" width="#{Canvas.coord(bounds.width)}" height="#{Canvas.coord(bounds.height)}" rx="0.00" shape-rendering="auto"  />\n</g>)
          end
        end
      end
    end
  end
end
