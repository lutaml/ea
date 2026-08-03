# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Single source of truth for emitting `<text>` SVG elements.
      # Handles:
      #
      # - Decimal `x`/`y` formatting (`%.2f`): matches EA's
      #   `x="11.00" y="19.00"` encoding.
      # - Always-present rotation transform: even when rotation is 0,
      #   EA emits `transform="rotate(-0.00 X Y)"`.
      # - Proper XML escaping of content.
      # - Optional `textLength` integer (computed by caller).
      #
      # Replaces the duplicated `build_text` helpers across
      # HeaderRenderer, AttributeRenderer, OperationRenderer,
      # EnumerationLiteralRenderer, Labels, and DiagramFrame.
      class TextRenderer
        DEFAULT_FILL = "#000000"
        DEFAULT_ROTATION = -0.00
        DEFAULT_STROKE_IN_TEXT = "#000000"
        DEFAULT_WIDTH_FACTOR = 0.65

        attr_reader :content, :x, :y, :family, :size, :weight, :style,
                    :fill, :text_length, :rotation, :size_unit,
                    :stroke_in_text, :width_factor

        def initialize(content:, x:, y:, family:, size:, weight: 400,
                       style: "normal", fill: DEFAULT_FILL,
                       text_length: nil, rotation: DEFAULT_ROTATION,
                       size_unit: "px",
                       stroke_in_text: DEFAULT_STROKE_IN_TEXT,
                       width_factor: DEFAULT_WIDTH_FACTOR)
          @content = content.to_s
          @x = x
          @y = y
          @family = family
          @size = size
          @weight = weight
          @style = style
          @fill = fill
          @text_length = text_length
          @rotation = rotation
          @size_unit = size_unit
          @stroke_in_text = stroke_in_text
          @width_factor = width_factor
        end

        def to_svg
          attrs = format_attrs
          style = format_style
          %(<text #{attrs} textLength="#{formatted_text_length}" style="#{style}" xml:space="preserve" transform="#{formatted_transform}">#{escaped_content}</text>)
        end

        private

        def format_attrs
          %(x="#{format('%.2f', x)}" y="#{format('%.2f', y)}")
        end

        def format_style
          "font-family:#{family}; font-weight:#{weight}; font-style:#{style}; font-size:#{size}#{size_unit}; fill:#{fill};fill-opacity:1.00; stroke:#{stroke_in_text}; stroke-opacity:0.00 stroke-width:0; white-space: pre;"
        end

        def self.estimate_width(text, size, width_factor = 0.65)
          content = text.to_s
          space_count = content.count(" ")
          letter_count = content.length - space_count
          letter_count * size * width_factor + space_count * size * 0.3
        end

        def formatted_text_length
          return text_length.to_i.to_s if text_length

          TextRenderer.estimate_width(content, size, width_factor).round.to_s
        end

        def formatted_transform
          "rotate(#{format('%<r>.2f', r: rotation)} #{format('%.2f', x)} #{format('%.2f', y)})"
        end

        def escaped_content
          content.gsub("&", "&amp;")
                 .gsub("<", "&lt;")
                 .gsub(">", "&gt;")
                 .gsub("\"", "&quot;")
        end
      end
    end
  end
end
