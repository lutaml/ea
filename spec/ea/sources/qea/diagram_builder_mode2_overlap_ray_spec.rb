# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  let(:ray) do
    { connector_type: "Generalization", source: [100, 300, 200, 100], target: [150, 100, 100, 100],
      path: "120:-250;135:-250;", geometry: "SX=3;SY=0;EX=-48;EY=0;EDGE=1;", style: "Mode=2;LWidth=2;" }
  end

  it "routes a stale Mode 2 jog as the vertical ray at the overlap midpoint plus SX" do
    expect(render_qea_route(**ray)[:paths]).to eq(["M 138 239 L 138 141"])
    expect(render_qea_route(**ray, geometry: "SX=-6;SY=0;EX=52;EY=0;EDGE=1;")[:paths]).to eq(["M 129 239 L 129 141"])
  end

  it "keeps other styles, missing Paths and non-overlapping boxes on their route" do
    controls = {
      "mode 3" => { style: "Mode=3;LWidth=2;" },
      "width 0" => { style: "Mode=2;LWidth=0;" },
      "no path" => { path: "" },
      "bent path" => { path: "120:-250;135:-240;" },
      "no overlap" => { target: [400, 100, 100, 100] },
      "association" => { connector_type: "Association" }
    }

    routes = controls.transform_values { |change| render_qea_route(**ray.merge(change))[:paths] }

    expect(routes).to eq(
      "mode 3" => ["M 55 239 L 55 190 L 70 190 L 85 141"],
      "width 0" => ["M 55 240 L 55 190 L 70 190 L 85 140"],
      "no path" => ["M 124 239 L 100 141"],
      "bent path" => ["M 55 239 L 55 190 L 70 180 L 85 141"],
      "no overlap" => ["M 55 239 L 55 190 L 70 190 L 335 141"],
      "association" => ["M 125 240 L 99 140", "M 108.58 153.01 L 99 140 L 96.97 156.03"]
    )
  end
  it "keeps an offset outside the shared span on its original stored jog" do
    result = render_qea_route(
      path: "175:-250;225:-250;", connector_type: "Generalization", style: "Mode=2;LWidth=2;",
      geometry: "SX=300;SY=0;EX=300;EY=0;EDGE=1;",
      source: [150, 300, 100, 100], target: [150, 100, 100, 100]
    )

    expect(result[:paths]).to eq(["M 60 239 L 60 190 L 110 190 L 110 141"])
  end
end
