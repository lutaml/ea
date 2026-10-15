# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:stair) do
    { connector_type: "Aggregation", source: [600, 300, 100, 100], target: [100, 100, 100, 100],
      path: "500:-350;500:-250;150:-250;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;", style: "Mode=3;LWidth=2;" }
  end

  it "preserves the saved bends when facing-edge routing would erase the staircase" do
    connector = nil
    result = render_qea_route(
      connector_type: "Aggregation", source: [487, 1246, 169, 80], target: [530, 180, 235, 159],
      path: "578:-1052;416:-1052;416:-389;648:-389;", style: "Mode=3;LWidth=2;",
      geometry: "SX=7;SY=-6;EX=2;EY=0;EDGE=1;"
    ) { |document| connector = document.diagrams.first.connectors.first }

    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[578, 1245], [578, 1052], [416, 1052], [416, 389], [648, 389], [648, 340]])
    expect(result[:paths].first.scan(" L ").size).to eq(5)
  end

  it "keeps an authored orthogonal stair-step and docks both ends on the outlines its legs point at" do
    expect(render_qea_route(**stair)[:paths]).to eq(["M 534 290 L 435 290 L 435 190 L 85 190 L 85 141"])
  end

  it "keeps other inputs on their existing route" do
    controls = {
      "two corners" => { path: "500:-350;500:-250;" },
      "diagonal leg" => { path: "500:-350;480:-250;150:-250;" },
      "zero-length leg" => { path: "500:-350;500:-350;150:-350;" },
      "corner inside source" => { path: "650:-350;650:-250;150:-250;" },
      "thin stroke" => { style: "Mode=3;LWidth=0;" },
      "generalization" => { connector_type: "Generalization" },
      "tree style" => { style: "Mode=3;TREE=V;LWidth=2;" }
    }

    routes = controls.transform_values { |change| render_qea_route(**stair.merge(change))[:paths] }

    expect(routes).to eq(
      "two corners" => ["M 534 290 L 435 290 L 435 190 L 135 141"],
      "diagonal leg" => ["M 534 290 L 435 290 L 415 190 L 85 190 L 85 141"],
      "zero-length leg" => ["M 534 290 L 435 290 L 435 290 L 85 290 L 85 141"],
      "corner inside source" => ["M 585 240 L 585 290 L 585 190 L 85 190 L 85 141"],
      "thin stroke" => ["M 585 240 L 435 290 L 435 190 L 85 190 L 85 40"],
      "generalization" => ["M 534 290 L 435 290 L 435 190 L 85 190 L 85 141"],
      "tree style" => ["M 585 240 L 435 290 L 435 190 L 85 190 L 85 141"]
    )
  end
end
