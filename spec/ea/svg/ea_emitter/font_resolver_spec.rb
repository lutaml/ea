require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::FontResolver do
  let(:element_with_font) do
    Ea::Model::DiagramElement.new(
      id: "e1",
      font_family: "Calibri",
      font_size: 10,
      font_bold: false,
      font_italic: true
    )
  end
  let(:element_without_font) do
    Ea::Model::DiagramElement.new(id: "e2")
  end
  let(:diagram) do
    Ea::Model::Diagram.new(
      id: "d1", name: "D",
      elements: [element_with_font, element_without_font,
                 Ea::Model::DiagramElement.new(id: "e3", font_family: "Calibri", font_size: 10)]
    )
  end
  let(:resolver) { described_class.new(diagram) }

  describe "#family_for" do
    it "returns explicit font when set" do
      expect(resolver.family_for(element_with_font)).to eq("Calibri")
    end

    it "falls back to diagram default when nil" do
      expect(resolver.family_for(element_without_font)).to eq("Calibri")
    end
  end

  describe "#size_for" do
    it "returns explicit size when set" do
      expect(resolver.size_for(element_with_font)).to eq(10)
    end

    it "falls back to diagram default when nil" do
      expect(resolver.size_for(element_without_font)).to eq(10)
    end
  end

  describe "#weight_for" do
    it "returns 700 when bold" do
      element_with_font.font_bold = true
      expect(resolver.weight_for(element_with_font)).to eq(700)
    end

    it "returns 400 when not bold" do
      expect(resolver.weight_for(element_with_font)).to eq(400)
    end
  end

  describe "#style_for" do
    it "returns italic when italic" do
      expect(resolver.style_for(element_with_font)).to eq("italic")
    end

    it "returns normal when not italic" do
      element_with_font.font_italic = false
      expect(resolver.style_for(element_with_font)).to eq("normal")
    end
  end

  context "with theme :119" do
    let(:theme) { Ea::Theme::Registry.lookup("119") }
    let(:resolver) { described_class.new(diagram, theme: theme) }

    it "uses Carlito from theme when element has no font" do
      expect(resolver.family_for(element_without_font)).to eq("Carlito")
    end

    it "uses diagram-default size (10) when other elements specify sizes" do
      # Diagram has elements with font_size=10, so diagram_default_size
      # returns 10 (most common). Theme font_size=7 is NOT used for
      # elements — it only applies to frame label.
      expect(resolver.size_for(element_without_font)).to eq(10)
    end

    it "element-level font still wins over theme" do
      expect(resolver.family_for(element_with_font)).to eq("Calibri")
    end
  end
end
