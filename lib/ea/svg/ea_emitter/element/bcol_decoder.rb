# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Decodes EA's BGR-encoded BCol/LCol integers into "#RRGGBB"
        # hex strings. EA stores color as a Win32 COLORREF: R in low
        # byte, G in mid byte, B in high byte.
        #
        # Returns nil when bgr_int is nil OR equals -1 (EA's sentinel
        # for "no color override" — callers fall through to a
        # stereotype-derived default).
        class BColDecoder
          SENTINEL = -1

          def self.to_hex(bgr_int)
            return nil if bgr_int.nil? || bgr_int == SENTINEL

            r = bgr_int & 0xff
            g = (bgr_int >> 8) & 0xff
            b = (bgr_int >> 16) & 0xff
            format("#%02X%02X%02X", r, g, b)
          end
        end
      end
    end
  end
end
