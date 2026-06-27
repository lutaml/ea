# frozen_string_literal: true

module Ea
  module Diagram
    module ElementRenderers
      # Base renderer for diagram elements
      class BaseRenderer
        include Ea::Diagram::Util

        attr_reader :element, :style_resolver

        def initialize(element, style_resolver)
          @element = element
          @style_resolver = style_resolver
        end

        # Render the element as SVG
        # @return [String] SVG content for the element
        def render
          style = style_resolver.resolve_element_style(element)

          <<~SVG
            <g class="lutaml-diagram-element lutaml-diagram-#{element[:type]}"
               data-element-id="#{element[:id]}"
               data-element-type="#{element[:type]}">
              #{render_shape(style)}
              #{render_label(style)}
            </g>
          SVG
        end

        def render_shape(_style)
          ""
        end

        def render_label(style) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          return "" unless element[:name]

          x = element[:x] || 0
          y = element[:y] || 0
          width = element[:width] || 120
          height = element[:height] || 80

          # Center the label
          text_x = x + (width / 2)
          # Slight vertical offset for better centering
          text_y = y + (height / 2) + 5

          <<~SVG
            <text x="#{text_x}"
                  y="#{text_y}"
                  text-anchor="middle"
                  dominant-baseline="middle"
                  font-family="#{style[:font_family]}"
                  font-size="#{style[:font_size]}"
                  font-weight="#{style[:font_weight] || 'normal'}"
                  fill="#{style[:text_color] || '#000000'}"
                  class="lutaml-diagram-label">
              #{escape_text(element[:name])}
            </text>
          SVG
        end

        def escape_text(text)
          return "" unless text

          text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
            .gsub("'", "&apos;")
        end
      end
    end
  end
end
