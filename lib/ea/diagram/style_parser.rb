# frozen_string_literal: true

# StyleParser is a thin color utility. Style orchestration (defaults,
# EA-parsed overrides, connector-type dispatch) lives in StyleResolver.
#
# Historically this class held a parallel style-resolution API
# (`parse_element_style`, `parse_connector_style`, `get_base_element_style`,
# `element_specific_style`, `parse_ea_style_string`, `stereotype_style`).
# That API was unused — callers went through StyleResolver's
# `resolve_element_style` / `resolve_connector_style` instead. The duplicate
# API was removed on 2026-06-27 to fix the MECE violation (two style
# pipelines for the same concern).
#
# What remains is `color_from_ea_color`, the BGR-integer → hex color
# converter that StyleResolver uses when parsing EA style strings.

module Ea
  module Diagram
    class StyleParser
      # EA's default fill color (light yellow) used when an EA color integer
      # is zero / unset.
      DEFAULT_FILL_COLOR = "#FFFFCC"

      # Convert EA color integer (BGR) to hex color string.
      #
      # EA stores colors as BGR integers in DiagramObject.style strings
      # (e.g. "BCol=16764159"). A zero value means "use the EA default".
      #
      # @param ea_color [Integer] EA BGR color value
      # @return [String] Hex color string (e.g. "#FFFFCC")
      def color_from_ea_color(ea_color)
        return DEFAULT_FILL_COLOR if ea_color.zero?

        b = (ea_color & 0xFF0000) >> 16
        g = (ea_color & 0x00FF00) >> 8
        r = ea_color & 0x0000FF

        format("#%02X%02X%02X", r, g, b)
      end
    end
  end
end
