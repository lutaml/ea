# frozen_string_literal: true

RSpec.describe Ea::Fonts::Metrics do
  include CarlitoGdiSpecHelpers

  it "uses the measured GDI advance of m at logical height 12 italic" do
    expect(carlito("m", style: "italic", logical_height: 12)).to eq(10)
  end

  it "matches the native textLength of _AbstractGeometricAggregate at height 12 italic" do
    expect(carlito("_AbstractGeometricAggregate", weight: 400, style: "italic", logical_height: 12)).to eq(150)
  end

  it "keeps the quantized advance of m at height 12 regular" do
    expect(carlito("m", weight: 400, logical_height: 12)).to eq(10)
  end

  it "keeps native Latin widths at the default logical height" do
    expect(carlito("_TransportationObject", weight: 400, style: "italic")).to eq(119)
    expect(carlito("uro::LengthAttribute", weight: 700)).to eq(117)
  end

  it "keeps the unmeasured quantized path for Arial" do
    expect(described_class.text_length("m", 9, family: "Arial", style: "italic", logical_height: 12)).to eq(10)
  end
end
