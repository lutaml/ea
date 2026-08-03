# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Shapescript do
  describe "Parser extensions (TODO 45)" do
    it "parses var declaration and uses it in a rectangle" do
      source = <<~SHAPESCRIPT
        shape MyIcon {
          var w = 10;
          var h = 5;
          rectangle(0, 0, w, h);
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(1)
      expect(shapes.first.kind).to eq(:rectangle)
      expect(shapes.first.params).to eq([0, 0, 10, 5])
    end

    it "evaluates arithmetic in expressions" do
      source = <<~SHAPESCRIPT
        shape MyIcon {
          var x = 5;
          rectangle(0, 0, x * 2, x + 10);
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.first.params).to eq([0, 0, 10, 15])
    end

    it "evaluates if-true branch" do
      source = <<~SHAPESCRIPT
        shape MyIcon {
          if (true) {
            rectangle(1, 1, 2, 2);
          }
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(1)
      expect(shapes.first.params).to eq([1, 1, 2, 2])
    end

    it "skips if-false branch" do
      source = <<~SHAPESCRIPT
        shape MyIcon {
          if (false) {
            rectangle(1, 1, 2, 2);
          }
          rectangle(3, 3, 4, 4);
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(1)
      expect(shapes.first.params).to eq([3, 3, 4, 4])
    end

    it "evaluates else branch when condition is false" do
      source = <<~SHAPESCRIPT
        shape MyIcon {
          if (false) {
            rectangle(1, 1, 2, 2);
          } else {
            rectangle(5, 5, 6, 6);
          }
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(1)
      expect(shapes.first.params).to eq([5, 5, 6, 6])
    end

    it "parses label primitive" do
      source = 'shape S { label("hello"); }'
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(1)
      expect(shapes.first.kind).to eq(:label)
      expect(shapes.first.params).to eq(["hello"])
    end

    it "preserves existing basic primitives" do
      source = "shape S { rectangle(0, 0, 10, 10); ellipse(5, 5, 4, 4); }"
      shapes = described_class::Parser.parse(source)
      expect(shapes.map(&:kind)).to eq(%i[rectangle ellipse])
    end

    it "handles nested shapes (subshapes)" do
      source = <<~SHAPESCRIPT
        shape Outer {
          shape Inner {
            rectangle(0, 0, 5, 5);
          }
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(1)
      expect(shapes.first.kind).to eq(:rectangle)
    end
  end

  describe "Renderer with labels" do
    it "renders label as SVG text element" do
      shape = described_class::Shape.new(kind: :label, params: ["Hi"])
      svg = described_class::Renderer.render([shape])
      expect(svg).to include("<text")
      expect(svg).to include("Hi")
    end

    it "escapes special characters in labels" do
      shape = described_class::Shape.new(kind: :label, params: ["<b>"])
      svg = described_class::Renderer.render([shape])
      expect(svg).to include("&lt;b&gt;")
    end
  end
end
