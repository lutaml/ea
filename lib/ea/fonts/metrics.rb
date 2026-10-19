# frozen_string_literal: true

require "json"

module Ea
  module Fonts
    # Advance-width metrics for the fonts EA's published SVGs use:
    # Carlito (metric-compatible with Calibri), Arial, and Arial
    # Narrow. EA's exported textLength values encode per-family,
    # per-style, per-POINT-SIZE scale factors applied to the font's
    # design advances (fitted by exact-count maximization against
    # EA-published SVGs), so text widths computed here match EA's
    # output to sub-pixel precision — far tighter than any legacy
    # fitted-codepoint table, and style/size aware.
    module Metrics
      DATA_PATH = File.expand_path("carlito_metrics.json", __dir__)

      # Maps (bold, italic) to the data-file style key.
      STYLE_KEYS = {
        [false, false] => :regular,
        [true, false] => :bold,
        [false, true] => :italic,
        [true, true] => :bold_italic
      }.freeze

      # Families metric-compatible with a data-file family (the key
      # is rendered even when the QEA named the other one).
      FAMILY_ALIASES = {
        "calibri" => "Carlito",
        "carlito" => "Carlito",
        "arial" => "Arial",
        "arial narrow" => "Arial Narrow",
        "cambria" => "Cambria"
      }.freeze

      # Cambria measurements are in SVG units at 7pt, not em advances.
      # Unmeasured characters and other sizes/styles must use the fallback.
      CAMBRIA_7_REGULAR_WIDTHS = JSON.parse(File.read(
                                              File.expand_path("cambria_7_regular_widths.json", __dir__)
                                            )).freeze
      # Styled ASCII advances come from Cambria's native TTF metrics,
      # quantized at the same 10px logical height as EA's 7pt font.
      # Bold uses monochrome hinted advances from the native TTF.
      CAMBRIA_7_STYLED_WIDTHS = JSON.parse(File.read(
                                             File.expand_path("cambria_7_styled_widths.json", __dir__)
                                           )).freeze
      CAMBRIA_7_GUILLEMET_PAIR_WIDTH = 10
      private_constant :CAMBRIA_7_REGULAR_WIDTHS, :CAMBRIA_7_STYLED_WIDTHS,
                       :CAMBRIA_7_GUILLEMET_PAIR_WIDTH

      # Advance used for codepoints missing from the tables.
      DEFAULT_ADVANCE = 0.25

      # Inferred subpixel steps that reproduce EA's near-half-pixel rounding.
      GDI_SUBPIXELS = 64

      # Carlito/Arial have no CJK glyphs; EA's renderer falls back to
      # a proportional CJK font whose advances measure ~0.709em at
      # the NOMINAL size (not scaled by the per-style factors) —
      # fitted from EA-published textLengths (52 mixed-script
      # samples).
      CJK_ADVANCE = 0.709
      CJK_RANGES = [
        (0x3000..0x303F),   # CJK punctuation
        (0x3040..0x309F),   # Hiragana
        (0x30A0..0x30FF),   # Katakana
        (0x4E00..0x9FFF),   # CJK Unified Ideographs
        (0xFF00..0xFFEF)    # Halfwidth/Fullwidth forms
      ].freeze

      module_function

      # EA's Cambria 7pt compartment rows use a 12px cell; Carlito
      # uses 13px. Keep unmeasured sizes and pixel fonts on their
      # configured spacing.
      def compartment_line_height(size, family:, unit: "pt", offset: 6, logical_height: nil)
        return size + offset - 1 if compact_compartment_font?(size, family: family, unit: unit)

        # Source sizes 90 and 100 both export as 9pt but retain
        # distinct 12px and 13px logical heights. Apply that same
        # source-height delta to the existing compartment spacing.
        adjustment = if logical_height && unit == "pt" &&
                        GDI_HEIGHT_FAMILIES.include?(resolve_family(family))
                       logical_height - gdi_logical_height(size)
                     else
                       0
                     end
        size + offset + adjustment
      end

      def gdi_logical_height(size)
        (size.to_f * 10 / 7).round
      end

      # Quantize before rounding: near-half-pixel Carlito advances
      # round up in EA's output. The 1/64px step is inferred.
      def gdi_pixel_advance(advance, height)
        ((advance * height * GDI_SUBPIXELS).round / GDI_SUBPIXELS.to_f).round
      end
      private_class_method :gdi_pixel_advance

      def compact_compartment_font?(size, family:, unit: "pt")
        family.to_s.casecmp("Cambria").zero? && size == 7 && unit == "pt"
      end

      # Width of `text` in EA's exported SVG units for the given pt
      # size, or nil when the family is not metric-compatible.
      #
      # EA's GDI driver quantizes each glyph advance to an integer
      # pixel count at the logical font height H = round(pt * 10/7)
      # (Carlito: 7pt -> H10, 9pt -> H13) and the published
      # textLength is the SUM of those per-glyph integers - corpus
      # fitted to 97-100% exact on 10k Carlito texts (bold 7pt
      # 1666/1671). The legacy sum-then-round model matched only 27%.
      def text_length(text, size_pt, family: nil, weight: nil, style: nil, logical_height: nil)
        return nil unless supported_family?(family)
        return nil if text.nil? || text.empty?

        return cambria_text_length(text, size_pt, weight, style) if resolve_family(family) == "Cambria"

        advance_text_length(text, size_pt, family, weight, style, logical_height)
      end

      def advance_text_length(text, size_pt, family, weight, style, logical_height)
        resolved = resolve_family(family)
        if GDI_HEIGHT_FAMILIES.include?(resolved)
          height = logical_height || gdi_logical_height(size_pt)
          table = table_for(family, weight, style)
          latin = 0
          cjk_count = 0
          text.each_char do |ch|
            if cjk?(ch.ord)
              cjk_count += 1
            else
              latin += gdi_pixel_advance(table[cp_key(ch)] || DEFAULT_ADVANCE, height)
            end
          end
          return latin + cjk_count * CJK_ADVANCE * size_pt.to_f
        end

        _latin, cjk_count = split_advance(text, family: family,
                                                 weight: weight, style: style)
        (_latin * size_pt.to_f * factor_for(family, size_pt, weight, style) +
         cjk_count * CJK_ADVANCE * size_pt.to_f).round(3)
      end

      private_class_method :advance_text_length

      def cambria_text_length(text, size_pt, weight, style)
        return nil unless size_pt.to_f.to_r == 7
        return nil unless ["", "0", "400", "normal", "700", "bold"].include?(weight.to_s)
        return nil unless ["", "normal", "italic"].include?(style.to_s)

        key = STYLE_KEYS.fetch([bold?(weight), italic?(style)])
        return cambria_styled_length(text, key) unless key == :regular

        return cambria_ascii_length(text) unless text.start_with?("«") && text.end_with?("»")

        inner_width = cambria_ascii_length(text[1...-1])
        inner_width + CAMBRIA_7_GUILLEMET_PAIR_WIDTH if inner_width
      end
      private_class_method :cambria_text_length

      def cambria_styled_length(text, key)
        table = CAMBRIA_7_STYLED_WIDTHS.fetch(key.to_s)
        widths = text.each_char.map { |char| table[char] }
        widths.sum unless widths.empty? || widths.include?(nil)
      end
      private_class_method :cambria_styled_length

      def cambria_ascii_length(text)
        widths = text.each_char.map { |char| CAMBRIA_7_REGULAR_WIDTHS[char] }
        widths.sum unless widths.empty? || widths.include?(nil)
      end
      private_class_method :cambria_ascii_length

      # Families whose EA driver quantizes per-glyph advances
      # (fitted from published textLengths).
      GDI_HEIGHT_FAMILIES = %w[Carlito Arial].freeze

      def supported_family?(family)
        !resolve_family(family).nil?
      end

      def resolve_family(family)
        FAMILY_ALIASES[family.to_s.downcase]
      end

      # Returns [latin_em (factor-scaled later), cjk_glyph_count].
      def split_advance(text, family: nil, weight: nil, style: nil)
        table = table_for(family, weight, style)
        latin = 0.0
        cjk = 0
        text.each_char.each do |ch|
          if cjk?(ch.ord)
            cjk += 1
          else
            latin += table[cp_key(ch)] || DEFAULT_ADVANCE
          end
        end
        [latin, cjk]
      end

      def cjk?(cp)
        CJK_RANGES.any? { |range| range.cover?(cp) }
      end

      # EA's scale factor varies by point size (GDI quantization):
      # Carlito regular fits 1.390 at 7pt but 1.440 at 9pt. Sizes
      # without a fitted entry use the style's default (7pt, the
      # corpus's dominant size).
      def factor_for(family, size_pt, weight, style)
        style = STYLE_KEYS.fetch([bold?(weight), italic?(style)], :regular).to_s
        table = data["factors"].fetch(resolve_family(family), {})
                                  .fetch(style, {})
        table[size_pt.to_i.to_s] || table["default"] || 1.0
      end

      def table_for(family, weight, style)
        style = STYLE_KEYS.fetch([bold?(weight), italic?(style)], :regular).to_s
        data["advance"].fetch(resolve_family(family), {}).fetch(style, {})
      end

      def data
        @data ||= JSON.parse(File.read(DATA_PATH))
      end

      def bold?(weight)
        %w[700 bold].include?(weight.to_s)
      end

      def italic?(style)
        style.to_s == "italic"
      end

      def cp_key(ch)
        format("U+%04X", ch.ord)
      end

      # Resolves a family's four style TTFs through the fontist gem
      # (system index + downloaded formulas). Style variants are
      # identified from each file's head.macStyle bits — filenames
      # vary across fontist formulas and system copies ("ArialBd",
      # "Arial Narrow Bold"), so name-matching is unreliable. The
      # first file matching each style wins (fontist orders the
      # downloaded formulas ahead of system copies). Empty when
      # fontist is unavailable or the family is not installed.
      def font_files_for(family)
        require "fontist"
        Fontist::SystemFont.find(family).each_with_object({}) do |path, out|
          next unless path.downcase.end_with?(".ttf")

          style = style_from_mac_style(path)
          next unless style

          out[style] ||= path
        end
      rescue LoadError, StandardError => e
        raise if ENV["EA_FONTS_DEBUG"]

        {}
      end

      # head.macStyle: bit 0 = BOLD, bit 1 = ITALIC.
      def style_from_mac_style(path)
        require "fontisan"
        font = Fontisan::FontLoader.load(path)
        mac_style = font.table("head").mac_style
        key = [mac_style & 1 == 1, mac_style & 2 == 2]
        STYLE_KEYS[key]
      end

      # Carlito's data-file name (historical) differs from the
      # fontist family name used to resolve its TTFs.
      def carlito_font_files
        font_files_for("Carlito")
      end

      # Reads advance widths from a TTF via the fontisan gem (used by
      # `rake fonts:validate` to re-derive the tables).
      def advances_from_font(path)
        require "fontisan"
        font = Fontisan::FontLoader.load(path)
        hmtx = font.table("hmtx")
        hmtx.parse_with_context(font.table("hhea").number_of_h_metrics,
                                font.table("maxp").num_glyphs)
        upem = font.table("head").units_per_em
        cmap = font.table("cmap").unicode_mappings
        cmap.each_with_object({}) do |(cp, gid), out|
          adv = hmtx.metric_for(gid)[:advance_width]
          out[cp] = (adv.to_f / upem).round(4) if adv
        end
      end

    end
  end
end
