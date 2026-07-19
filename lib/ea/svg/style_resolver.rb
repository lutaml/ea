# frozen_string_literal: true

module Ea
  module Svg
    # Translates the parsed style hash (from
    # Ea::Sources::Qea::DiagramStyleParser, or the equivalent for
    # XMI) into SVG-friendly attributes. EA packs colors as
    # integers (e.g. 16777215 = white); we translate to CSS hex.
    class StyleResolver
      DEFAULT_FILL = "#ffffff"
      DEFAULT_STROKE = "#000000"
      DEFAULT_FONT_COLOR = "#000000"

      attr_reader :style

      def initialize(style_hash)
        @style = style_hash || {}
      end

      def fill_color
        color_from_ea(style[:bcol]) || DEFAULT_FILL
      end

      def stroke_color
        color_from_ea(style[:lcol]) || DEFAULT_STROKE
      end

      def font_color
        color_from_ea(style[:fcol]) || DEFAULT_FONT_COLOR
      end

      def stroke_width
        raw = style[:lwd]
        return 1 if raw.nil? || raw.to_s.empty?

        Integer(raw)
      rescue ArgumentError
        1
      end

      def to_svg_attrs
        {
          fill: fill_color,
          stroke: stroke_color,
          "stroke-width": stroke_width
        }
      end

      # EA stores colors as decimal integers in BGR byte order
      # (low byte = red, high byte = blue). The high byte may hold
      # alpha in some variants; we treat anything above 0xFFFFFF
      # as opaque.
      def color_from_ea(raw)
        return nil if raw.nil? || raw.to_s.empty?

        # Hex strings (e.g. from XMI): passthrough.
        return "##{raw}" if raw.to_s.match?(/\A[0-9a-fA-F]{6}\z/)

        Integer(raw.to_s)
      rescue ArgumentError
        nil
      else
        # Convert BGR integer → RGB hex.
        value = Integer(raw)
        b = (value >> 16) & 0xff
        g = (value >> 8) & 0xff
        r = value & 0xff
        format("#%02X%02X%02X", r, g, b)
      end
    end
  end
end
