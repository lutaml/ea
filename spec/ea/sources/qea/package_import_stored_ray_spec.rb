# frozen_string_literal: true

require "spec_helper"

# Keep the source-backed ray and its boundary preservation controls together.
RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  let(:package_ray) do
    { source: [256, 30, 130, 80], target: [482, 30, 130, 80],
      geometry: "SX=0;SY=-8;EX=0;EY=-8;EDGE=2;",
      connector_type: "Package", style: "Mode=3;LWidth=0;", path: nil }
  end

  it "uses the saved mathematical row for an empty-Path package import" do
    result = render_qea_route(**package_ray) do |document|
      connector = document.diagrams.first.connectors.first
      expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
        .to eq([[386, 78], [482, 78]])
      expect([connector.source_anchor.y, connector.target_anchor.y]).to eq([78, 78])
    end

    expect(result[:paths].first).to eq("M 165 88 L 261 88")
  end

  it "clips a reverse import on the same stored row" do
    result = render_qea_route(**package_ray.merge(source: [482, 30, 130, 80], target: [256, 30, 130, 80]))

    expect(result[:paths]).to eq(["M 261 88 L 165 88", "M 180 83 L 165 88 L 180 93"])
  end

  [
    ["an authored bend", { path: "430:-140;" }],
    ["unequal stored rows", { geometry: "SX=0;SY=-8;EX=0;EY=-12;EDGE=2;" }],
    ["another route mode", { style: "Mode=2;LWidth=0;" }],
    ["another line width", { style: "Mode=3;LWidth=2;" }]
  ].each do |description, overrides|
    it "preserves #{description}" do
      expect(render_qea_route(**package_ray.merge(overrides))[:paths])
        .to eq(["M 100 120 L 326 120 L 326 120"])
    end
  end

  it "preserves an origin outside its source box" do
    result = render_qea_route(**package_ray.merge(geometry: "SX=100;SY=-8;EX=0;EY=-8;EDGE=2;"))

    expect(result[:paths]).to eq(["M 165 85 L 326 85 L 326 120", "M 321 105 L 326 120 L 331 105"])
  end
end
