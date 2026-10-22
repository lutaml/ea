# frozen_string_literal: true

require "spec_helper"

# Native legend titles are Cambria bold 12pt (logical height 17).
RSpec.describe "Ea::Fonts::Metrics Cambria CJK-only runs outside 7pt" do
  include CambriaCjkTitleHelpers

  it "measures the native legend title 凡例 (Cambria bold 12pt) as 34" do
    expect(width("凡例", 12, "700", legend_title: true)).to eq(34)
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

  it "draws a bold CJK legend title at 12pt with the regular logical-17 advances, not the bold ones" do
    %w[都市計画データ 土石流].each do |text|
      expect(width(text, 12, "700", legend_title: true)).to eq(table_width("17:400:normal", text))
      expect(width(text, 12, "700", legend_title: true)).not_to eq(table_width("17:700:normal", text))
    end
  end

  it "measures a longer bold 12pt legend title exactly (都市計画データ = 108)" do
    expect(width("都市計画データ", 12, "700", legend_title: true)).to eq(108)
  end

  it "keeps the bold table for bold CJK below logical height 17 (9pt 凡例 = 28)" do
    expect(width("凡例", 9, "700")).to eq(28)
    expect(width("凡例", 9, "700")).to eq(table_width("13:700:normal", "凡例"))
  end

  it "measures a Cambria CJK run at a size outside the measured table without the 7pt tables" do
    expect(Ea::Fonts::Metrics.text_length("土石流", 12, family: "Cambria", weight: "0")).to eq(51)
  end
end

RSpec.describe "Ea::Fonts::Metrics Cambria CJK runs outside 7pt, other contexts" do
  let(:metrics) { Ea::Fonts::Metrics }
  let(:renderer) { Ea::Svg::EaEmitter::TextRenderer }

  it "honours the source logical height like Carlito (H12 vs H13)" do
    expect(metrics.text_length("凡例", 9, family: "Cambria", logical_height: 12)).to eq(24)
    expect(metrics.text_length("凡例", 9, family: "Cambria", logical_height: 13)).to eq(26)
  end

  it "treats a zero logical height as absent for Carlito and Cambria" do
    expect(metrics.text_length("凡例", 9, family: "Carlito", logical_height: 0)).to eq(26.0)
    expect(metrics.text_length("凡例", 9, family: "Cambria", logical_height: 0)).to eq(26)
  end

  it "keeps the bold table for non-legend text at H17 (都市計画 = 72)" do
    expect(metrics.text_length("都市計画", 12, family: "Cambria", weight: "700")).to eq(72)
  end

  it "uses regular advances for a bold legend title at H17 (凡例 = 34)" do
    expect(metrics.text_length("凡例", 12, family: "Cambria", weight: "700", legend_title: true)).to eq(34)
  end

  it "does not widen the legend-title rule below H17" do
    expect(metrics.text_length("都市計画データ", 7, family: "Cambria", weight: "700", legend_title: true)).to eq(70)
  end

  it "never narrows a run when a character is appended" do
    widths = ["凡例", "凡例一", "凡例A", "凡例 "].map do |text|
      renderer.estimate_width(text, 12, family: "Cambria", weight: "700")
    end
    expect(widths[1]).to be > widths[0]
    expect(widths[2]).to be > widths[0]
    expect(widths[3]).to be > widths[0]
  end

  it "keeps an all-Latin Cambria run on the glyph estimate" do
    expect(renderer.estimate_width("Hello", 12, family: "Cambria", weight: "700"))
      .to eq("Hello".each_char.sum { |c| (renderer::GLYPH_WIDTHS[c] || renderer::GLYPH_FALLBACK) * 12 })
  end
end
