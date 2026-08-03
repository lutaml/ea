# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Theme::Registry do
  describe ".lookup" do
    it "returns default theme for nil" do
      theme = described_class.lookup(nil)
      expect(theme.id).to eq("default")
    end

    it "returns default theme for empty string" do
      theme = described_class.lookup("")
      expect(theme.id).to eq("default")
    end

    it "returns theme 119 for ':119' string" do
      theme = described_class.lookup(":119")
      expect(theme.id).to eq("119")
      expect(theme.font_family).to eq("Carlito")
      expect(theme.font_size).to eq(7)
      expect(theme.font_size_unit).to eq("pt")
      expect(theme.text_color).to eq("#000000")
      expect(theme.border_color).to eq("#9A8484")
      expect(theme.stroke_width).to eq(2)
    end

    it "returns theme 119 for '119' string" do
      theme = described_class.lookup("119")
      expect(theme.id).to eq("119")
    end

    it "returns default theme for unknown id" do
      theme = described_class.lookup(":999")
      expect(theme.id).to eq("default")
    end
  end

  describe ".register (OCP)" do
    after do
      described_class.lookup("test_theme")
      # Registry doesn't have delete; themes persist for the process
    end

    it "supports adding new themes without modifying existing code" do
      custom = Ea::Theme::Definition.new(
        id: "test_theme", name: "Test",
        font_family: "TestFont",
        font_size: 12, font_size_unit: "px",
        text_color: "#ABCDEF", border_color: "#FEDCBA",
        element_border_width: 3
      )
      described_class.register(custom)

      looked_up = described_class.lookup("test_theme")
      expect(looked_up.id).to eq("test_theme")
      expect(looked_up.font_family).to eq("TestFont")
    end
  end

  describe ".default" do
    it "is not themed" do
      expect(described_class.default.themed?).to be(false)
    end
  end

  describe "theme 119" do
    it "is themed" do
      expect(described_class.lookup("119").themed?).to be(true)
    end

    it "uses weight 0 for normal text (EA's Carlito convention)" do
      expect(described_class.lookup("119").text_weight_normal).to eq(400)
    end
  end
end
