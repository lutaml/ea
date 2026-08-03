# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"

RSpec.describe "Ea::Theme end-to-end lifecycle" do
  let(:xmi_path) { File.expand_path("../../../examples/exports/simple/model.xml", __dir__) }
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(xmi_path)) }
  let(:doc) { Ea::Sources::Xmi::Adapter.new(root, xmi_path).to_document }
  let(:diagram) { doc.diagrams.find { |d| d.name == "Package A.1.1" } }

  describe "reading theme from source data" do
    it "returns default theme when no style_ex is present" do
      diagram.style_ex = nil
      expect(diagram.theme.id).to eq("default")
      expect(diagram.theme.themed?).to be(false)
    end

    it "extracts theme from style_ex when present" do
      diagram.style_ex = "Theme=:119;SuppressFOC=1"
      expect(diagram.theme.id).to eq("119")
      expect(diagram.theme.themed?).to be(true)
    end

    it "auto-detects Theme from XMI style2 on diagrams that carry it" do
      expect(diagram.style_ex).to include("Theme=:119")
      expect(diagram.theme.id).to eq("119")
      expect(diagram.theme.font_family).to eq("Carlito")
    end
  end

  describe "setting theme by ID" do
    before { diagram.theme = "119" }

    it "resolves to the correct Definition" do
      expect(diagram.theme.id).to eq("119")
      expect(diagram.theme.font_family).to eq("Carlito")
      expect(diagram.theme.font_size).to eq(7)
      expect(diagram.theme.font_size_unit).to eq("pt")
      expect(diagram.theme.text_color).to eq("#000000")
      expect(diagram.theme.border_color).to eq("#9A8484")
      expect(diagram.theme.stroke_width).to eq(2)
    end
  end

  describe "editing theme via Definition#with" do
    before do
      diagram.theme = "119"
      variant = diagram.theme.with(id: "119_test", text_color: "#FF0000")
      diagram.theme = variant
    end

    it "creates a variant with overridden fields" do
      expect(diagram.theme.id).to eq("119_test")
      expect(diagram.theme.text_color).to eq("#FF0000")
    end

    it "preserves inherited fields from base theme" do
      expect(diagram.theme.font_family).to eq("Carlito")
      expect(diagram.theme.font_size).to eq(7)
      expect(diagram.theme.border_color).to eq("#9A8484")
    end
  end

  describe "creating a custom theme from scratch" do
    let(:custom) do
      Ea::Theme::Definition.new(
        id: "dark_test", name: "Dark Theme Test",
        font_family: "Helvetica", font_size: 10,
        text_color: "#FFFFFF", border_color: "#333333",
        element_border_width: 1,
        fills: { "Ea::Model::Klass" => "#1A1A1A" }
      )
    end

    before { diagram.theme = custom }

    it "uses the custom theme" do
      expect(diagram.theme.id).to eq("dark_test")
      expect(diagram.theme.text_color).to eq("#FFFFFF")
    end

    it "registers it in the Registry for lookup" do
      expect(Ea::Theme::Registry.lookup("dark_test").name).to eq("Dark Theme Test")
    end
  end

  describe "rendering SVG with theme :119" do
    before { diagram.theme = "119" }

    it "emits themed font in SVG output" do
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
      parsed = Nokogiri::XML(svg)

      first_text_style = parsed.css("text").first&.attr("style") || ""
      expect(first_text_style).to include("Carlito")
      expect(first_text_style).to include("fill:#000000")
    end

    it "emits themed stroke color" do
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
      parsed = Nokogiri::XML(svg)

      element_groups = parsed.css('g[style*="stroke:#000000"]')
      expect(element_groups.size).to be > 0
    end

    it "emits themed stroke-width" do
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
      parsed = Nokogiri::XML(svg)

      sw2_groups = parsed.css('g[style*="stroke-width:2"]')
      expect(sw2_groups.size).to be > 0
    end
  end

  describe "rendering SVG with default theme (no theme)" do
    before { diagram.style_ex = nil }

    it "emits default font in SVG output" do
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
      parsed = Nokogiri::XML(svg)

      # Default theme uses element-stored or Calibri fallback
      first_text_style = parsed.css("text").first&.attr("style") || ""
      expect(first_text_style).to include("font-family:")
      expect(first_text_style).to include("fill:#000000")
    end
  end

  describe "Registry listing" do
    it "lists all available themes" do
      ids = Ea::Theme::Registry.all.map(&:id)
      expect(ids).to include("default")
      expect(ids).to include("119")
    end
  end

  describe "Definition immutability" do
    let(:theme) { Ea::Theme::Registry.lookup("119") }

    it "freezes the fills hash" do
      expect(theme.fills).to be_frozen
    end

    it "returns new instance from #with" do
      variant = theme.with(text_color: "#ABCDEF")
      expect(variant).not_to be(theme)
      expect(theme.text_color).to eq("#000000")
      expect(variant.text_color).to eq("#ABCDEF")
    end
  end

  describe "Definition#fill_for" do
    let(:theme) { Ea::Theme::Registry.lookup("119") }

    it "returns nil when no per-type fills are configured" do
      klass = Ea::Model::Klass.new(id: "k1", name: "X")
      expect(theme.fill_for(klass)).to be_nil
    end

    it "returns nil for Enumeration too" do
      enum = Ea::Model::Enumeration.new(id: "e1", name: "Enum")
      expect(theme.fill_for(enum)).to be_nil
    end

    it "returns nil for unknown classifier type" do
      stub_class = Class.new
      expect(theme.fill_for(stub_class.new)).to be_nil
    end
  end
end
