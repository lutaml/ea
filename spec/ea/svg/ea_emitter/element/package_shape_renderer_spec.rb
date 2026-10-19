# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
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

  it "uses the font size for the first baseline and family metrics for subsequent lines" do
    records = [
      ["Carlito", 9, "pt", [75, 90]],
      ["Cambria", 7, "pt", [73, 85]],
      ["Carlito", 7, "pt", [73, 86]],
      ["Carlito", 9, "px", [73, 86]]
    ]
    records.each do |family, size, unit, expected|
      svg = described_class.render(
        bounds, fill: "#FAF3F0", stroke: "#9A8484", stroke_width: 2,
                label: "Schema", stereotype: "applicationSchema",
                family: family, size: size, size_unit: unit
      )
      texts = Nokogiri::XML(svg).css("text")

      expect(texts.map { |text| text["y"].to_f }).to eq(expected)
      expect(texts.map(&:text)).to eq(["«applicationSchema»", "Schema"])
      expect(texts.map { |text| text["x"] }).to eq(["40.00", "40.00"])
    end
  end

  it "preserves the single-line Cambria anchor and package polygons" do
    svg = described_class.render(
      bounds, fill: "#FAF3F0", stroke: "#9A8484", stroke_width: 2,
              label: "Schema", family: "Cambria", size: 7
    )
    nodes = Nokogiri::XML(svg)

    expect(nodes.css("text").map { |text| [text["x"], text["y"]] })
      .to eq([["40.00", "73.00"]])
    expect(nodes.css("polygon").map { |polygon| polygon["points"] })
      .to eq(["35 79 169 79 169 234 35 234 35 79",
              "35 60 140 60 140 79 35 79 35 60"])
  end
end
