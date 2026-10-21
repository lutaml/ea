# frozen_string_literal: true

require "spec_helper"

# Native legend titles are Cambria bold 12pt (logical height 17).
RSpec.describe "Ea::Fonts::Metrics Cambria CJK-only runs outside 7pt" do
  def width(text, size, weight)
    Ea::Svg::EaEmitter::TextRenderer.estimate_width(text, size, family: "Cambria", weight: weight).round
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
end
