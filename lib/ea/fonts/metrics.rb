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
        "arial narrow" => "Arial Narrow"
      }.freeze

      # Advance used for codepoints missing from the tables.
      DEFAULT_ADVANCE = 0.25

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

      # Width of `text` in EA's exported SVG units for the given pt
      # size, or nil when the family is not metric-compatible.
      #
      # EA's GDI driver quantizes each glyph advance to an integer
      # pixel count at the logical font height H = round(pt * 10/7)
      # (Carlito: 7pt -> H10, 9pt -> H13) and the published
      # textLength is the SUM of those per-glyph integers - corpus
      # fitted to 97-100% exact on 10k Carlito texts (bold 7pt
      # 1666/1671). The legacy sum-then-round model matched only 27%.
      def text_length(text, size_pt, family: nil, weight: nil, style: nil)
        return nil unless supported_family?(family)
        return nil if text.nil? || text.empty?

        resolved = resolve_family(family)
        if GDI_HEIGHT_FAMILIES.include?(resolved)
          height = (size_pt.to_f * 10 / 7).round
          table = table_for(family, weight, style)
          latin = 0
          cjk_count = 0
          text.each_char do |ch|
            if cjk?(ch.ord)
              cjk_count += 1
            else
              latin += ((table[cp_key(ch)] || DEFAULT_ADVANCE) * height).round
            end
          end
          return latin + cjk_count * CJK_ADVANCE * size_pt.to_f
        end

        _latin, cjk_count = split_advance(text, family: family,
                                                 weight: weight, style: style)
        (_latin * size_pt.to_f * factor_for(family, size_pt, weight, style) +
         cjk_count * CJK_ADVANCE * size_pt.to_f).round(3)
      end

      # Families whose EA driver quantizes per-glyph advances
      # (fitted from published textLengths).
      GDI_HEIGHT_FAMILIES = %w[Carlito].freeze

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
