# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Centralizes SVG style strings used across emitters.
      # Connector and marker styles are now computed dynamically
      # via stroke_width parameter — only TEXT_GROUP remains as
      # a constant (shared across all text-emitting renderers).
      module Style
        TEXT_GROUP = "stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00"
      end
    end
  end
end
