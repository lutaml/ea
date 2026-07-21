# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits the background layer: white rect over the full canvas.
      module Background
        module_function

        def render(canvas)
          %(<g style="fill:#FFFFFF;fill-opacity:1.00;">\n  <rect x="#{canvas.min_x}" y="#{canvas.min_y}" width="#{canvas.width}" height="#{canvas.height}" shape-rendering="auto"/>\n</g>)
        end
      end
    end
  end
end
