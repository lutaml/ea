# frozen_string_literal: true

module CambriaCjkTitleHelpers
  CJK_FALLBACK_WIDTHS = File.expand_path("../../lib/ea/fonts/cjk_fallback_widths.json", __dir__)

  def width(text, size, weight, legend_title: false)
    Ea::Svg::EaEmitter::TextRenderer.estimate_width(text, size, family: "Cambria", weight: weight,
                                                                legend_title: legend_title).round
  end

  # Windows GDI advances (MS UI Gothic) the Cambria CJK fallback is read from.
  def table_width(key, text)
    table = JSON.parse(File.read(CJK_FALLBACK_WIDTHS)).fetch("widths").fetch(key)
    text.each_char.sum { |char| table.fetch(char) }
  end
end
