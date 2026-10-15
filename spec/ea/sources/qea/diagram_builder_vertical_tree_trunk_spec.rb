# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  let(:parent_above) { { source: [150, 300, 100, 100], target: [150, 100, 100, 100] } }
  let(:parent_below) { { source: [150, 100, 100, 100], target: [400, 300, 100, 100] } }
  let(:geometry) { "SX=0;SY=-1;EX=0;EY=0;EDGE=1;" }

  it "draws a trunk bend stored twice as one bend" do
    result = render_qea_route(
      connector_type: "Generalization", path: "200:-250;200:-250;",
      geometry: geometry, style: "TREE=V;LWidth=2;", **parent_above
    )

    expect(result[:paths]).to eq(["M 85 239 L 85 190 L 85 141"])
  end

  it "docks a child below its parent on the facing edges at the adjacent bends" do
    result = render_qea_route(
      connector_type: "Aggregation", path: "175:-250;450:-250;",
      geometry: "EDGE=1;", style: "TREE=V;LWidth=2;", **parent_below
    )

    expect(result[:paths]).to eq(["M 60 140 L 60 190 L 335 190 L 335 240"])
  end

  it "leaves other tree styles on their existing route" do
    routes = ["TREE=H;LWidth=2;", "LWidth=2;"].to_h do |style|
      [style, render_qea_route(
        connector_type: "Aggregation", path: "175:-250;450:-250;",
        geometry: "EDGE=1;", style: style, **parent_below
      )[:paths]]
    end

    expect(routes.values).to all(eq(["M 85 40 L 60 190 L 335 190 L 335 240"]))
  end

  it "docks an Association tree on the facing edges at the adjacent bends" do
    result = render_qea_route(
      connector_type: "Association", path: "450:-250;200:-250;",
      geometry: geometry, style: "TREE=V;LWidth=0;", source: [400, 300, 100, 100], target: [150, 100, 100, 100]
    )

    expect(result[:paths]).to eq(["M 335 240 L 335 190 L 85 190 L 85 140", "M 91 155 L 85 140 L 79 155"])
  end
end
