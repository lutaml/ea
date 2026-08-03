# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/package_shape_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::PackageShapeRenderer do
  let(:bounds) { Ea::Model::Bounds.new(x: 35, y: 60, width: 134, height: 174) }

  describe ".render" do
    it "renders 2 polygons (tab + body) for a package without stereotype" do
      svg = described_class.render(
        bounds,
        fill: "#FAF3F0", stroke: "#9A8484", stroke_width: 2,
        label: "Test Schema", family: "Carlito", size: 7
      )
      polygons = svg.scan(/<polygon\b/).size
      expect(polygons).to eq(2)
    end

    it "renders 1 text line when no stereotype" do
      svg = described_class.render(
        bounds,
        fill: "#FAF3F0", stroke: "#9A8484", stroke_width: 2,
        label: "Test Schema", family: "Carlito", size: 7
      )
      expect(svg.scan(/<text\b/).size).to eq(1)
    end

    it "renders 2 text lines when stereotype is provided" do
      svg = described_class.render(
        bounds,
        fill: "#FAF3F0", stroke: "#9A8484", stroke_width: 2,
        label: "Test Schema", stereotype: "applicationSchema",
        family: "Carlito", size: 7
      )
      expect(svg.scan(/<text\b/).size).to eq(2)
    end

    it "emits the «stereotype» text wrapped in guillemets" do
      svg = described_class.render(
        bounds,
        fill: "#FAF3F0", stroke: "#9A8484", stroke_width: 2,
        label: "Test Schema", stereotype: "applicationSchema",
        family: "Carlito", size: 7
      )
      expect(svg).to include("«applicationSchema»")
    end

    it "uses tab width of 105 regardless of label length" do
      svg = described_class.render(
        bounds,
        fill: "#FAF3F0", stroke: "#9A8484", stroke_width: 2,
        label: "X",
        family: "Carlito", size: 7
      )
      # tab polygon = (35, 40, 140, 40, 140, 60, 35, 60) for single-line.
      # Width = 140-35 = 105.
      expect(svg).to include("140")
    end
  end
end