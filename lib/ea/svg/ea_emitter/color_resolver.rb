# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Single source of truth for fill + stroke color decisions.
      #
      # Theme :119 applies:
      #   - Border color (#9A8484) for element strokes
      #   - Attribute color (#66413F) for attribute text
      #   - Method color for operation text
      # Theme :119 does NOT apply:
      #   - Per-type fill colors (elements use default #FFFFFF)
      #   - Text color (#000000 black for non-attribute text)
      #
      # Precedence chain for fill:
      #   1. Element's BCol int (when present and not sentinel)
      #   2. Default fill (#FFFFFF)
      #
      # Precedence chain for stroke:
      #   1. Element's LCol int (when present and not sentinel)
      #   2. Theme border color (when theme is themed)
      #   3. Default stroke (#000000)
      class ColorResolver
        DEFAULT_FILL = "#FFFFFF"
        DEFAULT_STROKE = "#000000"

        attr_reader :theme, :stereotype_resolver

        def initialize(theme: nil, stereotype_resolver: Ea::Svg::StereotypeColorResolver.new)
          @theme = theme || Ea::Theme::Registry.default
          @stereotype_resolver = stereotype_resolver
        end

        def fill_for(element, classifier)
          bcol = Element::BColDecoder.to_hex(element&.background_color)
          return bcol if bcol

          DEFAULT_FILL
        end

        def stroke_for(element)
          lcol = Element::BColDecoder.to_hex(element&.line_color)
          return lcol if lcol
          return theme.border_color if theme.themed?

          DEFAULT_STROKE
        end

        def attribute_text_color
          theme.themed? ? (theme.attribute_color || DEFAULT_STROKE) : DEFAULT_STROKE
        end
      end
    end
  end
end
