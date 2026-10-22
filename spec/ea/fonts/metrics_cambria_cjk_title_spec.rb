# frozen_string_literal: true

require "spec_helper"

# Native legend titles are Cambria bold 12pt (logical height 17).
RSpec.describe "Ea::Fonts::Metrics Cambria CJK-only runs outside 7pt" do
  def width(text, size, weight)
    Ea::Svg::EaEmitter::TextRenderer.estimate_width(text, size, family: "Cambria", weight: weight).round
  end

  # Windows GDI advances (MS UI Gothic) the Cambria CJK fallback is read from.
  def table_width(key, text)
    table = JSON.parse(File.read(File.expand_path("../../../lib/ea/fonts/cjk_fallback_widths.json", __dir__)))
                .fetch("widths").fetch(key)
    text.each_char.sum { |char| table.fetch(char) }
  end

  it "measures the native legend title 凡例 (Cambria bold 12pt) as 34" do
    expect(width("凡例", 12, "700")).to eq(34)
  end

  it "keeps the bold table below logical height 17 (native 7pt bold 都市計画データ = 70)" do
    expect(width("都市計画データ", 7, "700")).to eq(70)
  end

  it "keeps 7pt regular Cambria rows exact" do
    expect(width("土石流", 7, "0")).to eq(30)
  end

  it "still falls back for a mixed Latin run outside 7pt" do
    expect(Ea::Fonts::Metrics.text_length("Aあ", 12, family: "Cambria", weight: "700")).to be_nil
  end

  it "draws a bold CJK run at 12pt with the regular logical-17 advances, not the bold ones" do
    %w[都市計画データ 土石流].each do |text|
      expect(width(text, 12, "700")).to eq(table_width("17:400:normal", text))
      expect(width(text, 12, "700")).not_to eq(table_width("17:700:normal", text))
    end
  end

  it "measures a longer bold 12pt title exactly (都市計画データ = 108)" do
    expect(width("都市計画データ", 12, "700")).to eq(108)
  end

  it "keeps the bold table for bold CJK below logical height 17 (9pt 凡例 = 28)" do
    expect(width("凡例", 9, "700")).to eq(28)
    expect(width("凡例", 9, "700")).to eq(table_width("13:700:normal", "凡例"))
  end

  it "measures a Cambria CJK run at a size outside the measured table without the 7pt tables" do
    expect(Ea::Fonts::Metrics.text_length("土石流", 12, family: "Cambria", weight: "0")).to eq(51)
  end
end
