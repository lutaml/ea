# frozen_string_literal: true

RSpec.describe Ea::Fonts::Metrics do
  include SourceSansProSpecHelpers

  {
    ["Concept B", 700] => 44, ["Concept C", 700] => 44,
    ["[Detailed notes that describe the ", 0] => 130, ["concept.]", 0] => 36,
    ["0..*", 0] => 13, ["Relationship One", 0] => 67,
    ["Relationship Two", 0] => 68, ["1", 0] => 5
  }.each do |(text, weight), native|
    it "matches the native italic textLength of #{text.inspect} (weight #{weight})" do
      expect(source_sans_pro_length(text, weight: weight, style: "italic")).to eq(native)
    end
  end

  it "uses the regular and bold advance tables (em 0.829/0.861 for m, 0.544/0.576 for A)" do
    expect([source_sans_pro_length("m", weight: 400), source_sans_pro_length("m", weight: 700)]).to eq([8, 9])
    expect([source_sans_pro_length("A", weight: 400), source_sans_pro_length("A", weight: 700)]).to eq([5, 6])
  end
end

RSpec.describe Ea::Fonts::Metrics, "outside Source Sans Pro" do
  it "keeps other families at their base widths" do
    two = "Relationship Two"
    carlito = ->(**opts) { described_class.text_length(two, 7, family: "Carlito", **opts) }
    expect([carlito.call(weight: 400), carlito.call(weight: 400, style: "italic")]).to eq([67, 67])
    expect(described_class.text_length(two, 9, family: "Carlito", weight: 700)).to eq(93)
    expect(described_class.text_length(two, 7, family: "Arial", weight: 400)).to eq(79)
    expect(described_class.text_length(two, 7, family: "Cambria", weight: 400)).to eq(76)
  end

  it "keeps the glyph estimate for an unknown family" do
    width = Ea::Svg::EaEmitter::TextRenderer.estimate_width("Relationship Two", 7, nil,
                                                            family: "Zzz Unknown", weight: 400)
    expect(width).to eq(67.459)
  end
end
