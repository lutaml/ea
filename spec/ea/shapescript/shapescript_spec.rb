# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Shapescript do
  describe "Parser" do
    it "parses a rectangle primitive" do
      source = <<~SHAPESCRIPT
        shape MyIcon {
          rectangle(0, 0, 10, 10);
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(1)
      expect(shapes.first.kind).to eq(:rectangle)
      expect(shapes.first.params).to eq([0, 0, 10, 10])
    end

    it "parses multiple primitives in one shape" do
      source = <<~SHAPESCRIPT
        shape MyIcon {
          rectangle(0, 0, 10, 10);
          ellipse(5, 5, 4, 4);
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(2)
      expect(shapes.map(&:kind)).to eq(%i[rectangle ellipse])
    end

    it "parses polygon with N points" do
      source = "shape S { polygon(0,0, 10,0, 5,10); }"
      shapes = described_class::Parser.parse(source)
      expect(shapes.first.kind).to eq(:polygon)
      expect(shapes.first.params).to eq([0, 0, 10, 0, 5, 10])
    end

    it "parses line and path primitives" do
      source = <<~SHAPESCRIPT
        shape S {
          line(0, 0, 10, 10);
          path(0, 0, 5, 5, 10, 0);
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.map(&:kind)).to eq(%i[line path])
    end

    it "ignores comments" do
      source = <<~SHAPESCRIPT
        // top-level comment
        shape S {
          /* block comment */
          rectangle(1, 2, 3, 4);
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      expect(shapes.size).to eq(1)
    end

    it "returns empty array for nil/empty" do
      expect(described_class::Parser.parse(nil)).to eq([])
      expect(described_class::Parser.parse("")).to eq([])
    end
  end

  describe "Renderer" do
    it "renders a rectangle as SVG rect" do
      shape = described_class::Shape.new(kind: :rectangle, params: [0, 0, 10, 10])
      svg = described_class::Renderer.render([shape])
      expect(svg).to include("<rect")
      expect(svg).to include('width="10"')
      expect(svg).to include('height="10"')
    end

    it "renders a polygon with all points" do
      shape = described_class::Shape.new(kind: :polygon, params: [0, 0, 10, 0, 5, 10])
      svg = described_class::Renderer.render([shape])
      expect(svg).to include("<polygon")
      expect(svg).to include("0,0 10,0 5,10")
    end

    it "renders multiple shapes joined" do
      shapes = [
        described_class::Shape.new(kind: :rectangle, params: [0, 0, 10, 10]),
        described_class::Shape.new(kind: :ellipse, params: [5, 5, 4, 4])
      ]
      svg = described_class::Renderer.render(shapes)
      expect(svg).to include("<rect")
      expect(svg).to include("<ellipse")
    end

    it "honors fill/stroke overrides" do
      shape = described_class::Shape.new(kind: :rectangle, params: [0, 0, 5, 5])
      svg = described_class::Renderer.render([shape], fill: "#FF0000", stroke: "#00FF00")
      expect(svg).to include('fill="#FF0000"')
      expect(svg).to include('stroke="#00FF00"')
    end
  end

  describe "end-to-end" do
    it "parses and renders a FeatureType icon" do
      source = <<~SHAPESCRIPT
        shape FeatureTypeIcon {
          rectangle(0, 0, 16, 16);
          polygon(8, 2, 14, 8, 8, 14, 2, 8);
        }
      SHAPESCRIPT
      shapes = described_class::Parser.parse(source)
      svg = described_class::Renderer.render(shapes, fill: "#FAF1EC",
                                              stroke: "#69738C")
      expect(svg).to include("<rect")
      expect(svg).to include("<polygon")
      expect(svg).to include("8,2 14,8 8,14 2,8")
    end
  end
end
