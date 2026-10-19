# frozen_string_literal: true

require "spec_helper"
require "ea/fonts/metrics"

RSpec.describe Ea::Fonts::Metrics do
  describe ".compartment_line_height" do
    it "uses the measured Cambria point cell and preserves other font settings" do
      expect(described_class.compartment_line_height(7, family: "Cambria")).to eq(12)
      expect(described_class.compartment_line_height(7, family: "CAMBRIA", offset: 10)).to eq(16)
      expect(described_class.compartment_line_height(7, family: "Carlito")).to eq(13)
      expect(described_class.compartment_line_height(9, family: "Cambria")).to eq(15)
      expect(described_class.compartment_line_height(7, family: "Cambria", unit: "px")).to eq(13)
    end
  end

  describe ".text_length" do
    it "returns nil for unsupported families" do
      expect(described_class.text_length("X", 7, family: "Comic Sans")).to be_nil
      expect(described_class.text_length("X", 7, family: nil)).to be_nil
    end

    it "returns nil for empty text" do
      expect(described_class.text_length("", 7, family: "Carlito")).to be_nil
      expect(described_class.text_length(nil, 7, family: "Carlito")).to be_nil
    end

    it "measures published Cambria regular text at seven points" do
      {
        "+roleTwo" => 42,
        "Operation B(int): void" => 96,
        "elements: xs:double [12] {ordered}" => 153,
        "XYScale = 999999999.99999988" => 148
      }.each do |text, width|
        expect(described_class.text_length(text, 7, family: "Cambria"))
          .to eq(width)
        expect(described_class.text_length(text, "7", family: "CAMBRIA",
                                                      weight: 400, style: "normal"))
          .to eq(width)
      end
    end

    it "measures an enclosing Cambria stereotype pair without guessing glyph widths" do
      {
        "«property»" => 48,
        "«ApplicationSchema»" => 93,
        "«interface»" => 48,
        "«Type»" => 32,
        "«type»" => 29
      }.each do |text, width|
        expect(described_class.text_length(text, 7, family: "Cambria"))
          .to eq(width)
        expect(described_class.text_length(text, 7, family: "Cambria", weight: 0))
          .to eq(width)
      end
    end

    it "quantizes native Cambria styled advances at seven points" do
      [
        ["uro::OtherConstruction", 700, "normal", 112],
        ["tun::IntTunnelInstallation", 700, "normal", 122],
        ["uro::DataQualityAttribute", "bold", "normal", 121],
        ["tun::_Opening", 700, "italic", 65],
        ["_CityObject", 400, "italic", 46]
      ].each do |text, weight, style, width|
        expect(described_class.text_length(text, 7, family: "Cambria",
                                                    weight: weight, style: style)).to eq(width)
      end
      expect(described_class.text_length("日本", 7, family: "Cambria", weight: 700)).to be_nil
    end

    it "keeps unsupported Cambria sizes and styles on the fallback path" do
      [6, 7.1, 9].each do |size|
        expect(described_class.text_length("«property»", size,
                                           family: "Cambria")).to be_nil
      end
      %w[300 500].each do |weight|
        expect(described_class.text_length("+roleTwo", 7, family: "Cambria",
                                                          weight: weight)).to be_nil
      end
      %w[oblique].each do |style|
        expect(described_class.text_length("+roleTwo", 7, family: "Cambria",
                                                          style: style)).to be_nil
      end
    end

    it "returns nil for unmeasured Cambria characters and empty text" do
      [nil, "", "role/Two", "role_7", "日本", "«»", "«property",
       "property»", "««property»»", "«property» «type»", "«signal» Signal A()"].each do |text|
        expect(described_class.text_length(text, 7, family: "Cambria"))
          .to be_nil
      end
    end

    it "quantizes each glyph advance at the GDI logical height" do
      # Carlito: H = round(pt * 10/7) - 7pt -> 10, 9pt -> 13; each
      # glyph advance is round(em * H) and the textLength is the
      # integer sum (corpus-fitted, bold 7pt 1666/1671 exact).
      seven = described_class.text_length("Hello", 7, family: "Carlito")
      nine = described_class.text_length("Hello", 9, family: "Carlito")
      table = described_class.data["advance"]["Carlito"]["regular"]
      exp7 = "Hello".each_char.sum { |ch| (table["U+%04X" % ch.ord] * 10).round }
      exp9 = "Hello".each_char.sum { |ch| (table["U+%04X" % ch.ord] * 13).round }
      expect(seven).to eq(exp7.to_f)
      expect(nine).to eq(exp9.to_f)
    end

    # EA-published textLengths constrain the inferred subpixel rounding.
    [
      ["class: gml:CodeType [0..1]", 400, "normal", 136],
      ["uro::LargeCustomerFacilityAttribute", 700, "normal", 200],
      ["uro::LengthAttribute", 700, "normal", 117],
      ["uro::UtilityLink", 700, "italic", 82],
      ["tran::TransportationComplex", 700, "normal", 160],
      ["_TransportationObject", 400, "italic", 119]
    ].each do |text, weight, style, expected|
      it "measures Carlito 9pt #{weight} #{style} #{text.inspect} as #{expected}" do
        expect(described_class.text_length(text, 9, family: "Carlito", weight: weight, style: style))
          .to eq(expected)
      end
    end

    # Arial's design advances are read from the installed Arial.ttf
    # (periodcentered = 682/2048 em), not fitted: at H14 that is 4.66px.
    it "uses the Arial font's own advance for the middle dot" do
      expect(described_class.text_length("·", 10, family: "Arial")).to eq(5)
    end

    it "treats Calibri as metric-compatible with Carlito" do
      expect(described_class.text_length("Hello", 7, family: "Calibri"))
        .to eq(described_class.text_length("Hello", 7, family: "Carlito"))
    end

    it "resolves family names case-insensitively" do
      expect(described_class.text_length("X", 7, family: "ARIAL"))
        .to eq(described_class.text_length("X", 7, family: "Arial"))
    end

    it "measures Arial Narrow narrower than Arial" do
      arial = described_class.text_length("Model Integration", 9,
                                          family: "Arial")
      narrow = described_class.text_length("Model Integration", 9,
                                           family: "Arial Narrow")
      expect(narrow).to be < arial
    end

    it "boldens via the bold advance table" do
      regular = described_class.text_length("Bold text", 7, family: "Carlito")
      bold = described_class.text_length("Bold text", 7, family: "Carlito",
                                                         weight: "700")
      expect(bold).to be > regular
    end

    it "measures CJK glyphs at the nominal size, unscaled by style" do
      em = 7 * described_class::CJK_ADVANCE
      expect(described_class.text_length("日本", 7, family: "Carlito"))
        .to be_within(0.01).of(2 * em)
      expect(described_class.text_length("日本", 7, family: "Carlito",
                                                  weight: "700"))
        .to eq(described_class.text_length("日本", 7, family: "Carlito"))
    end
  end

  describe ".font_files_for" do
    it "classifies Carlito styles from the font's own macStyle bits" do
      files = described_class.font_files_for("Carlito")
      skip "Carlito not installed" if files.empty?

      expect(files.keys).to contain_exactly(:regular, :bold, :italic,
                                            :bold_italic)
    end
  end

  describe ".style_from_mac_style" do
    it "detects bold from the font file bits" do
      files = described_class.font_files_for("Carlito")
      skip "Carlito not installed" if files.empty?

      expect(described_class.style_from_mac_style(files[:bold])).to eq(:bold)
      expect(described_class.style_from_mac_style(files[:italic])).to eq(:italic)
      expect(described_class.style_from_mac_style(files[:regular])).to eq(:regular)
    end
  end
end
