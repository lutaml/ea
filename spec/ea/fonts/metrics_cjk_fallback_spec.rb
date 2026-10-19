# frozen_string_literal: true

require "spec_helper"

# Carlito and Cambria take CJK glyph advances from the measured MS UI Gothic table.
RSpec.describe "Ea::Fonts::Metrics CJK fallback advances" do
  include CjkFallbackHelpers

  # Native textLength values from the EA-published plateau SVGs.
  [
    ["都市計画基礎調査", 9, "Carlito", { weight: "700" }, 112],
    ["都市計画決定情報モデル", 9, "Carlito", { weight: "700" }, 147],
    ["交通（航路）モデル", 9, "Carlito", { weight: "700" }, 107],
    ["GMLに定義されたクラス", 9, "Carlito", { weight: "400", logical_height: 12 }, 109],
    ["(from 3D都市モデル)", 9, "Carlito", { weight: "400", style: "italic" }, 109],
    ["(from 3D都市モデル)", 7, "Cambria", { weight: "0", style: "italic" }, 85],
    ["土石流", 7, "Cambria", { weight: "0" }, 30]
  ].each do |text, size, family, font, native|
    it "measures #{text} in #{family} #{size}pt #{font} as native #{native}" do
      expect(emitted_width(text, size, family, **font)).to eq(native)
    end
  end

  it "keeps native Latin widths" do
    expect(emitted_width("uro::LengthAttribute", 9, "Carlito", weight: "700")).to eq(117)
    expect(emitted_width("_CityObject", 7, "Cambria", weight: "400", style: "italic")).to eq(46)
  end

  it "keeps the nominal CJK advance for an unmeasured logical height" do
    expect(Ea::Fonts::Metrics.text_length("都市", 9, family: "Carlito", logical_height: 11))
      .to be_within(0.001).of(2 * 0.709 * 9)
  end

  it "leaves Cambria sizes without a measured table on the fallback path" do
    expect(Ea::Fonts::Metrics.text_length("凡例", 12, family: "Cambria", weight: "700")).to be_nil
  end
end
