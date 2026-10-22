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
        "cambria" => "Cambria",
        "source sans pro" => "Source Sans Pro"
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
      # Per-family OS/2 win metrics and, where the font has one, its
      # 1:1 VDMX table (ppem => [ascent, descent] in pixels), read
      # from the font files named in each entry's version.
      VERTICAL_METRICS = JSON.parse(File.read(
                                      File.expand_path("vertical_metrics.json", __dir__)
                                    )).freeze
      # Carlito and Cambria have no CJK glyphs. EA's CJK widths for them
      # match MS UI Gothic's GDI advances, measured on Windows per
      # "height:weight:style"; that match does not prove the linked face.
      CJK_FALLBACK_WIDTHS = JSON.parse(File.read(
                                         File.expand_path("cjk_fallback_widths.json", __dir__)
                                       )).fetch("widths").freeze
      CJK_FALLBACK_FAMILIES = %w[Carlito Cambria].freeze
      # Logical height from which a bold Cambria CJK run uses regular advances.
      CAMBRIA_REGULAR_BOLD_MIN_HEIGHT = 17
      # Carlito ASCII advances measured on Windows per "height:weight:style";
      # they take precedence over the quantized design advances.
      CARLITO_GDI_WIDTHS = JSON.parse(File.read(
                                        File.expand_path("carlito_gdi_widths.json", __dir__)
                                      )).fetch("widths").freeze
      # Source Sans Pro design advances (em) per style, extracted from the
      # TTF hmtx tables; summed after the same per-glyph GDI quantization.
      SOURCE_SANS_PRO_ADVANCES = JSON.parse(File.read(
                                              File.expand_path("source_sans_pro_advances.json", __dir__)
                                            )).fetch("advance").freeze
      private_constant :CAMBRIA_7_REGULAR_WIDTHS, :CAMBRIA_7_STYLED_WIDTHS,
                       :CAMBRIA_7_GUILLEMET_PAIR_WIDTH, :VERTICAL_METRICS,
                       :CJK_FALLBACK_WIDTHS, :CJK_FALLBACK_FAMILIES, :CAMBRIA_REGULAR_BOLD_MIN_HEIGHT,
                       :CARLITO_GDI_WIDTHS, :SOURCE_SANS_PRO_ADVANCES

      # Advance used for codepoints missing from the tables.
      DEFAULT_ADVANCE = 0.25

      # Inferred subpixel steps that reproduce EA's near-half-pixel rounding.
      GDI_SUBPIXELS = 64

      # Advance for CJK glyphs with no measured fallback width: ~0.709em
      # at the NOMINAL size (not scaled by the per-style factors),
      # fitted from EA-published textLengths (52 mixed-script samples).
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
        logical_height = source_logical_height(logical_height)
        adjustment = if logical_height && unit == "pt" &&
                        GDI_HEIGHT_FAMILIES.include?(resolve_family(family))
                       logical_height - gdi_logical_height(size)
                     else
                       0
                     end
        size + offset + adjustment
      end

      # A source logical height of 0 or less (QEA floors tiny fontsz to
      # 0) carries no information: treat it as absent.
      def source_logical_height(height)
        height = height.to_i
        height if height.positive?
      end

      def gdi_logical_height(size)
        (size.to_f * 10 / 7).round
      end

      # GDI text-cell [ascent, descent] in pixels at logical height
      # `height`: the VDMX entry when the font has one (GDI prefers it
      # for hinted fonts), else the rounded usWinAscent/usWinDescent.
      # Nil when the family has no vertical data.
      def gdi_cell_metrics(family, height)
        data = VERTICAL_METRICS[resolve_family(family)]
        return nil unless data && height

        data.fetch("vdmx", {})[height.to_s] ||
          [data["win_ascent"], data["win_descent"]].map do |units|
            (units * height.to_f / data["units_per_em"]).round
          end
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
      #
      # `legend_title` marks a diagram-legend title, the only context in
      # which a bold Cambria CJK run takes regular-weight advances.
      def text_length(text, size_pt, family: nil, weight: nil, style: nil, logical_height: nil,
                      legend_title: false)
        return nil unless supported_family?(family)
        return nil if text.nil? || text.empty?

        if resolve_family(family) == "Cambria"
          return cambria_text_length(text, size_pt, weight, style, logical_height, legend_title: legend_title)
        end

        advance_text_length(text, size_pt, family, weight, style, logical_height)
      end

      def advance_text_length(text, size_pt, family, weight, style, logical_height)
        resolved = resolve_family(family)
        if GDI_HEIGHT_FAMILIES.include?(resolved)
          height = source_logical_height(logical_height) || gdi_logical_height(size_pt)
          table = table_for(family, weight, style)
          fallback = cjk_fallback_widths(resolved, height, weight, style)
          measured_latin = measured_carlito_widths(resolved, height, weight, style)
          latin = 0
          cjk_count = 0
          text.each_char do |ch|
            if cjk?(ch.ord)
              measured = fallback[ch]
              measured ? latin += measured : cjk_count += 1
            else
              latin += measured_latin[ch] ||
                       gdi_pixel_advance(table[cp_key(ch)] || DEFAULT_ADVANCE, height)
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

      # Measured fallback advances for `family` at this height and style,
      # keyed by character; empty when the configuration was not measured.
      def cjk_fallback_widths(family, height, weight, style)
        return {} unless CJK_FALLBACK_FAMILIES.include?(family)

        CJK_FALLBACK_WIDTHS.fetch("#{height}:#{bold?(weight) ? 700 : 400}:#{italic?(style) ? "italic" : "normal"}", {})
      end
      private_class_method :cjk_fallback_widths

      def measured_carlito_widths(family, height, weight, style)
        return {} unless family == "Carlito"

        CARLITO_GDI_WIDTHS.fetch("#{height}:#{bold?(weight) ? 700 : 400}:#{italic?(style) ? "italic" : "normal"}", {})
      end
      private_class_method :measured_carlito_widths

      # True for Cambria outside the 7pt tables, where a run is measured
      # character by character when it is not wholly in the CJK table.
      def piecewise_family?(family, size_pt)
        resolve_family(family) == "Cambria" && size_pt.to_f.to_r != 7
      end

      def cambria_text_length(text, size_pt, weight, style, logical_height = nil, legend_title: false)
        unless size_pt.to_f.to_r == 7
          return cambria_cjk_only_length(text, size_pt, weight, style, logical_height, legend_title: legend_title)
        end
        return nil unless ["", "0", "400", "normal", "700", "bold"].include?(weight.to_s)
        return nil unless ["", "normal", "italic"].include?(style.to_s)

        fallback = cambria_cjk_widths(weight, style)
        key = STYLE_KEYS.fetch([bold?(weight), italic?(style)])
        return cambria_styled_length(text, key, fallback) unless key == :regular

        return cambria_ascii_length(text, fallback) unless text.start_with?("«") && text.end_with?("»")

        inner_width = cambria_ascii_length(text[1...-1], fallback)
        inner_width + CAMBRIA_7_GUILLEMET_PAIR_WIDTH if inner_width
      end
      private_class_method :cambria_text_length

      # Cambria has no Latin table outside 7pt, but a run made only of
      # characters in the measured MS UI Gothic table is exact at the
      # measured height (the source logical height when it is positive,
      # else the one derived from the point size). A run with any other
      # character is nil here; TextRenderer.estimate_width then prices
      # the characters one at a time.
      #
      # EMPIRICAL FIT (decision a), legend titles only: EA draws a bold
      # Cambria legend title at logical height >= 17 with the
      # regular-weight advances (no synthetic-bold pixel), although the
      # Windows table records one. Checked on the 116 native legend
      # titles "凡例" (Cambria bold 12pt, H17): native textLength 34 =
      # 2 x 17, where the 17:700 entry would give 36. Every other bold
      # run, and a title below H17, keeps the bold table (native 7pt
      # bold "都市計画データ" = 70).
      def cambria_cjk_only_length(text, size_pt, weight, style, logical_height = nil, legend_title: false)
        height = source_logical_height(logical_height) || gdi_logical_height(size_pt)
        bold = bold?(weight) && !(legend_title && height >= CAMBRIA_REGULAR_BOLD_MIN_HEIGHT)
        widths = cjk_fallback_widths("Cambria", height, bold ? 700 : 400, style)
        advances = text.each_char.map { |char| widths[char] }
        advances.sum unless advances.include?(nil)
      end
      private_class_method :cambria_cjk_only_length

      def cambria_cjk_widths(weight, style)
        cjk_fallback_widths("Cambria", gdi_logical_height(7), weight, style)
      end
      private_class_method :cambria_cjk_widths

      def cambria_styled_length(text, key, fallback)
        table = CAMBRIA_7_STYLED_WIDTHS.fetch(key.to_s)
        widths = text.each_char.map { |char| table[char] || fallback[char] }
        widths.sum unless widths.empty? || widths.include?(nil)
      end
      private_class_method :cambria_styled_length

      def cambria_ascii_length(text, fallback)
        widths = text.each_char.map { |char| CAMBRIA_7_REGULAR_WIDTHS[char] || fallback[char] }
        widths.sum unless widths.empty? || widths.include?(nil)
      end
      private_class_method :cambria_ascii_length

      # Families whose EA driver quantizes per-glyph advances
      # (fitted from published textLengths).
      GDI_HEIGHT_FAMILIES = ["Carlito", "Arial", "Source Sans Pro"].freeze

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
        resolved = resolve_family(family)
        return SOURCE_SANS_PRO_ADVANCES.fetch(style) if resolved == "Source Sans Pro"

        data["advance"].fetch(resolved, {}).fetch(style, {})
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
