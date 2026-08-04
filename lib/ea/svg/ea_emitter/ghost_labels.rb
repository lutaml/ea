# frozen_string_literal: true

# frozen_string: true

module Ea
  module Svg
    module EaEmitter
      # Emits ghost classifier name `<text>` elements for connector
      # endpoints that reference off-canvas classifiers. Each ghost
      # label appears as italic text near the connector's on-canvas
      # endpoint.
      class GhostLabels
        DEFAULT_FAMILY = "Carlito"
        DEFAULT_SIZE = 9
        DEFAULT_UNIT = "pt"
        DEFAULT_FILL = "#000000"

        attr_reader :diagram, :canvas, :family, :size, :size_unit, :fill

        def initialize(diagram, canvas: nil, family: DEFAULT_FAMILY,
                       size: DEFAULT_SIZE, size_unit: DEFAULT_UNIT,
                       fill: DEFAULT_FILL)
          @diagram = diagram
          @canvas = canvas
          @family = family
          @size = size
          @size_unit = size_unit
          @fill = fill
        end

        def render
          texts = visible_connectors.flat_map do |connector|
            (connector.ghost_labels || []).map { |g| text_for(g) }
          end
          return "" if texts.empty?

          group_style = "stroke-width:1;stroke-linecap:round;" \
                        "stroke-linejoin:bevel; fill:#{fill};" \
                        "fill-opacity:1.00; stroke:#000000;" \
                        " stroke-opacity:0.00"
          %(<g style="#{group_style}">\n#{texts.join("\n")}\n</g>)
        end

        private

        def visible_connectors
          (diagram.connectors || []).select(&:renderable?)
        end

        def text_for(ghost)
          tx, ty = translate(ghost.anchor_x, ghost.anchor_y)
          TextRenderer.new(
            content: ghost.name.to_s,
            x: tx, y: ty,
            family: family, size: size, size_unit: size_unit,
            style: "italic", fill: fill
          ).to_svg
        end

        def translate(x, y)
          return [x, y] unless canvas

          [canvas.translate_x(x), canvas.translate_y(y)]
        end
      end
    end
  end
end
