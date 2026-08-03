# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Model::Diagram, "#theme API" do
  let(:diagram) { described_class.new(id: "d1", name: "Test") }

  describe "#theme (read)" do
    it "returns default theme when no style_ex" do
      expect(diagram.theme.id).to eq("default")
      expect(diagram.theme.themed?).to be(false)
    end

    it "returns theme from style_ex" do
      diagram.style_ex = "Theme=:119;SuppressFOC=1"
      expect(diagram.theme.id).to eq("119")
      expect(diagram.theme.themed?).to be(true)
      expect(diagram.theme.font_family).to eq("Carlito")
    end
  end

  describe "#theme= (set by ID)" do
    it "accepts Symbol ID" do
      diagram.theme = :"119"
      expect(diagram.theme.id).to eq("119")
    end

    it "accepts String ID with colon" do
      diagram.theme = ":119"
      expect(diagram.theme.id).to eq("119")
    end

    it "accepts String ID without colon" do
      diagram.theme = "119"
      expect(diagram.theme.id).to eq("119")
    end

    it "accepts 'default' to reset" do
      diagram.theme = "119"
      diagram.theme = "default"
      expect(diagram.theme.themed?).to be(false)
    end
  end

  describe "#theme= (set by Definition)" do
    it "registers and sets the Definition" do
      custom = Ea::Theme::Definition.new(
        id: "custom_red",
        name: "Red Theme",
        font_family: "Arial",
        font_size: 12,
        text_color: "#FF0000",
        border_color: "#CC0000",
        element_border_width: 3
      )
      diagram.theme = custom

      expect(diagram.theme.id).to eq("custom_red")
      expect(diagram.theme.text_color).to eq("#FF0000")
      expect(diagram.theme.font_family).to eq("Arial")
    end

    it "makes the Definition available via Registry" do
      custom = Ea::Theme::Definition.new(id: "test_lookup", name: "Test")
      diagram.theme = custom

      expect(Ea::Theme::Registry.lookup("test_lookup").name).to eq("Test")
    end
  end

  describe "#theme= (edit existing)" do
    it "supports creating a variant via Definition#with" do
      diagram.style_ex = "Theme=:119"
      edited = diagram.theme.with(id: "119_green", text_color: "#00FF00")
      diagram.theme = edited

      expect(diagram.theme.id).to eq("119_green")
      expect(diagram.theme.text_color).to eq("#00FF00")
      expect(diagram.theme.font_family).to eq("Carlito")
    end
  end

  describe "#theme_id" do
    it "returns override_id when set via theme=" do
      diagram.theme = "119"
      expect(diagram.theme_id).to eq("119")
    end

    it "returns style_ex Theme value when no override" do
      diagram.style_ex = "Theme=:119"
      expect(diagram.theme_id).to eq(":119")
    end

    it "returns nil when neither set" do
      expect(diagram.theme_id).to be_nil
    end
  end
end
