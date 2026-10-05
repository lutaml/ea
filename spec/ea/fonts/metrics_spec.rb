# frozen_string_literal: true

require "spec_helper"
require "ea/fonts/metrics"

RSpec.describe Ea::Fonts::Metrics do
  describe ".text_length" do
    it "returns nil for unsupported families" do
      expect(described_class.text_length("X", 7, family: "Comic Sans")).to be_nil
      expect(described_class.text_length("X", 7, family: nil)).to be_nil
    end

    it "returns nil for empty text" do
      expect(described_class.text_length("", 7, family: "Carlito")).to be_nil
      expect(described_class.text_length(nil, 7, family: "Carlito")).to be_nil
    end

    it "scales by the size-specific factor when fitted" do
      # Carlito regular: 7pt uses factor 1.390, 9pt uses 1.440.
      seven = described_class.text_length("Hello", 7, family: "Carlito")
      nine = described_class.text_length("Hello", 9, family: "Carlito")
      expect(nine / seven).to be_within(0.01).of(9 * 1.440 / (7 * 1.390))
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
