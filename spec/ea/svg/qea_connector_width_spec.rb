# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA connector and marker pen width" do
  include QeaMarkerHelpers

  {
    "LWidth=0 draws a 1px pen" => ["Mode=3;LWidth=0;", 1],
    "LWidth=2 draws a 2px pen" => ["Mode=3;LWidth=2;", 2],
    "a link without LWidth keeps the 2px default" => ["Mode=3;", 2],
    "an empty LWidth keeps the 2px default" => ["Mode=3;LWidth=;", 2]
  }.each do |label, (style, width)|
    it "#{label} for the line and its marker" do
      expect(pen_widths(style)).to eq(line: [width], marker: [width])
    end
  end

  let(:mixed_width_diagram) do
    connectors = [0, 2, 0].each_with_index.map do |width, index|
      Ea::Model::DiagramConnector.new(
        id: "c#{index}", connector_type: "Generalization", style: { lwidth: width },
        waypoints: [
          Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
          Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
        ]
      )
    end
    Ea::Model::Diagram.new(id: "d", name: "Mixed widths", connectors: connectors)
  end

  [Ea::Svg::EaEmitter::Connectors, Ea::Svg::EaEmitter::Markers].each do |emitter|
    it "keeps different widths apart when grouping #{emitter.name.split("::").last}" do
      layers = emitter.new(mixed_width_diagram, model_index: {}).layers

      expect(stroke_widths(layers)).to eq([1, 2])
      expect(layers.map(&:style_key).uniq.size).to eq(2)
      expect(layers.map { |layer| layer.body.scan(/<(?:path|polygon)\b/).size }).to eq([2, 1])
    end

    it "preserves each width in ungrouped #{emitter.name.split("::").last}" do
      layers = emitter.new(mixed_width_diagram, model_index: {}, grouped: false).layers

      expect(stroke_widths(layers)).to eq([1, 2, 1])
      expect(layers.size).to eq(3)
    end
  end
end
