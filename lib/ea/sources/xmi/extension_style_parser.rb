# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Parses EA's packed style string from
      # <xmi:Extension>/<elements>/<element>/@style. Returns a typed
      # Style struct so renderers consume typed fields.
      module ExtensionStyleParser
        module_function

        def parse(style_string)
          return Style.new if style_string.nil? || style_string.empty?

          kv = split_pairs(style_string)
          Style.new(
            background_color: int(kv["BCol"]),
            line_color: int(kv["LCol"]),
            line_width: int(kv["LWth"] || kv["LWidth"]),
            font_family: kv["font"],
            font_size: scale_font_size(kv["fontsz"]),
            bold: truthy?(kv["bold"]),
            italic: truthy?(kv["italic"]),
            underline: truthy?(kv["ul"]),
            black: truthy?(kv["black"]),
            hide_icon: truthy?(kv["HideIcon"]),
            duid: kv["DUID"],
            soid: kv["SOID"],
            eoid: kv["EOID"],
            mode: int(kv["Mode"]),
            color: int(kv["Color"]),
            hidden: truthy?(kv["Hidden"]),
            raw: style_string
          )
        end

        def split_pairs(str)
          str.split(";").filter_map do |pair|
            next nil unless pair.include?("=")

            key, value = pair.split("=", 2)
            key = key.to_s.strip
            [key, value] if key && !key.empty? && value && !value.empty?
          end.to_h
        end

        def int(value)
          return nil if value.nil? || value.empty?

          Integer(value)
        rescue ArgumentError
          nil
        end

        def truthy?(value)
          value == "1" || value == "true" || value == "-1"
        end

        def scale_font_size(value)
          return 13 if value.nil? || value.empty?

          pct = int(value)
          return 13 if pct.nil?

          (pct * 13 / 100).round
        end

        Style = Struct.new(
          :background_color, :line_color, :line_width,
          :font_family, :font_size,
          :bold, :italic, :underline, :black, :hide_icon,
          :duid, :soid, :eoid, :mode, :color, :hidden,
          :raw,
          keyword_init: true
        )
      end
    end
  end
end
