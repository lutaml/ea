# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # A single `<g>` block ready for inclusion in the SVG output.
      # Carries the style string and the body (one or more child
      # elements: `<path>`, `<polygon>`, `<text>`, `<rect>`).
      #
      # Emitters return Arrays of Layer objects. The Document
      # orchestrator either joins them as-is (per-entity ordering)
      # or buckets them by `style_key` for EA-style grouped output.
      Layer = Struct.new(:style_key, :style, :body, keyword_init: true) do
        def to_svg
          %(<g style="#{style}">\n#{body}\n</g>)
        end
      end
    end
  end
end
