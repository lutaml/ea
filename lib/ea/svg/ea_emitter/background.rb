# frozen_string_string: true

module Ea
  module Svg
    module EaEmitter
      module Background
        module_function

        def render(canvas)
          %(<g style="fill:#FFFFFF;fill-opacity:1.00;">\n  <rect x="0" y="0" width="#{canvas.width}" height="#{canvas.height}" shape-rendering="auto"/>\n</g>)
        end
      end
    end
  end
end
