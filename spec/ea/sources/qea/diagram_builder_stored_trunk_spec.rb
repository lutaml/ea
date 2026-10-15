# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  let(:geometry) { "SX=0;SY=0;EX=0;EY=0;EDGE=1;" }
  let(:overlapping) do
    { parent_above: { source: [150, 300, 100, 100], target: [150, 100, 100, 100] },
      parent_below: { source: [150, 100, 100, 100], target: [150, 300, 100, 100] } }
  end

  it "keeps the stored trunk of a flush Aggregation whose child sits below an overlapping parent" do
    result = render_qea_route(
      connector_type: "Aggregation", path: "175:-250;225:-250;",
      geometry: geometry, style: "Mode=3;TREE=V;LWidth=0;", **overlapping[:parent_below]
    )

    expect(result[:paths]).to eq(["M 60 140 L 60 190 L 110 190 L 110 240"])
  end

  it "keeps a straight stored trunk as one vertical route with its bend" do
    inputs = {
      "width-2 Aggregation" => { connector_type: "Aggregation", style: "Mode=3;TREE=V;LWidth=2;" },
      "flush Association" => { connector_type: "Association", style: "Mode=3;TREE=V;LWidth=0;" }
    }
    routes = inputs.transform_values do |input|
      render_qea_route(path: "200:-250;200:-250;", geometry: geometry, **input, **overlapping[:parent_above])[:paths]
    end

    expect(routes).to eq(
      "width-2 Aggregation" => ["M 85 239 L 85 190 L 85 141"],
      "flush Association" => ["M 85 240 L 85 190 L 85 140", "M 91 155 L 85 140 L 79 155"]
    )
  end

  it "keeps thin strokes and other tree modes on their flattened route" do
    routes = ["Mode=3;TREE=V;LWidth=2;", "Mode=3;TREE=H;LWidth=0;", "Mode=3;LWidth=0;"].to_h do |style|
      [style, render_qea_route(connector_type: "Aggregation", path: "175:-250;225:-250;", geometry: geometry,
                               style: style, **overlapping[:parent_below])[:paths]]
    end

    expect(routes).to eq(
      "Mode=3;TREE=V;LWidth=2;" => ["M 85 141 L 85 239"],
      "Mode=3;TREE=H;LWidth=0;" => ["M 85 140 L 85 240"],
      "Mode=3;LWidth=0;" => ["M 85 140 L 85 240"]
    )
  end
end
