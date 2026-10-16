# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Resolves saved classifier and placement fonts and EA's point sizes.
        module FontSettings
          private

          # Placement defaults inherit the classifier's saved font before the
          # diagram theme. A zero fontsz is EA's use-default marker.
          def effective_font_style(obj_row, style)
            object = database.find_object(obj_row.ea_object_id)
            defaults = DiagramStyleParser.parse(object&.styleex)
            {
              font: presence(style[:font]) || defaults[:font],
              fontsz: font_size_from(style) ? style[:fontsz] : defaults[:fontsz]
            }
          end

          def presence(value)
            value.nil? || value.to_s.empty? ? nil : value
          end

          # EA stores the element font size in tenths of a point and
          # renders it through GDI's double rounding: pixel height =
          # floor(tenths * 96 / 720), then point size =
          # floor(pixels * 72 / 96). A zero fontsz inherits the default.
          USE_DEFAULT_FONTSZ = [0].freeze
          GDI_DPI = 96

          def font_size_from(style_hash)
            raw = style_hash[:fontsz]
            return nil if raw.nil? || raw.to_s.empty?

            return nil if USE_DEFAULT_FONTSZ.include?(raw.to_i)

            pixels = (raw.to_f * GDI_DPI / 720).floor
            (pixels * 72.0 / GDI_DPI).floor
          end
        end
      end
    end
  end
end
