# frozen_string_literal: true

require "json"

module Ea
  module Fonts
    # Advance-width metrics for Carlito, metric-compatible with
    # Calibri. EA's exported textLength values encode Carlito
    # advances scaled by per-style factors, so text widths computed
    # here match EA's published SVGs to sub-pixel precision — far
    # tighter than the legacy fitted-codepoint table, and style-aware
    # (bold/italic variants), which the legacy table lacked.
    module Metrics
      DATA_PATH = File.expand_path("carlito_metrics.json", __dir__)

      # Maps (bold, italic) to the data-file style key.
      STYLE_KEYS = {
        [false, false] => :regular,
        [true, false] => :bold,
        [false, true] => :italic,
        [true, true] => :bold_italic
      }.freeze

      # Families whose glyph metrics match the Carlito tables.
      SUPPORTED_FAMILIES = %w[Carlito Calibri].freeze

      # Advance used for codepoints missing from the tables.
      DEFAULT_ADVANCE = 0.25

      # Carlito has no CJK glyphs; EA's renderer falls back to a
      # proportional CJK font whose advances measure ~0.709em at the
      # NOMINAL size (not scaled by the per-style factors) — fitted
      # from EA-published textLengths (52 mixed-script samples).
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
      def text_length(text, size_pt, family: nil, weight: nil, style: nil)
        return nil unless supported_family?(family)
        return nil if text.nil? || text.empty?

        latin, cjk_count = split_advance(text, weight: weight, style: style)
        (latin * size_pt.to_f * factor_for(weight, style) +
         cjk_count * CJK_ADVANCE * size_pt.to_f).round(3)
      end

      def supported_family?(family)
        SUPPORTED_FAMILIES.include?(family.to_s)
      end

      # Returns [latin_em (factor-scaled later), cjk_glyph_count].
      def split_advance(text, weight: nil, style: nil)
        table = table_for(weight, style)
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

      def factor_for(weight, style)
        data["factors"][STYLE_KEYS.fetch([bold?(weight), italic?(style)], :regular).to_s]
      end

      def table_for(weight, style)
        data["advance"][STYLE_KEYS.fetch([bold?(weight), italic?(style)], :regular).to_s]
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
    end
  end
end
