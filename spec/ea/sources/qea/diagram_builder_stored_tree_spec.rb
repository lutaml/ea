# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  it "retains valid tree bends when the boxes also admit a straight facing-edge route" do
    result = render_qea_route(
      connector_type: "Aggregation", source: [649, 331, 216, 241],
      target: [327, 8, 387, 193], path: "755:-251;520:-251;",
      geometry: "SX=0;SY=-1;EX=0;EY=0;EDGE=1;", style: "TREE=V;LWidth=2;"
    )

    expect(result[:paths]).to eq(["M 463 362 L 463 283 L 228 283 L 228 234"])
    expect(result[:markers]).to eq(["463 362 458 352 463 342 468 352"])
  end

  it "retains a tree trunk outside the overlap of the two boxes" do
    result = render_qea_route(
      connector_type: "Aggregation", source: [185, 699, 237, 139],
      target: [327, 8, 387, 193], path: "302:-251;520:-251;",
      geometry: "SX=0;SY=-1;EX=0;EY=0;EDGE=1;", style: "TREE=V;LWidth=2;"
    )

    expect(result[:paths]).to eq(["M 152 730 L 152 283 L 370 283 L 370 234"])
    expect(result[:markers]).to eq(["152 730 147 720 152 710 157 720"])
  end

  it "keeps thin strokes, other tree modes and invalid stored bends on their existing route" do # rubocop:disable Metrics/BlockLength
    input = {
      connector_type: "Aggregation", source: [649, 331, 216, 241],
      target: [327, 8, 387, 193], path: "755:-251;520:-251;",
      geometry: "SX=0;SY=-1;EX=0;EY=0;EDGE=1;", style: "TREE=V;LWidth=2;"
    }
    controls = [
      { style: "TREE=H;LWidth=2;" }, { style: "LWidth=2;" },
      { path: "900:-251;520:-251;" }, { path: "755:-251;900:-251;" },
      { path: "755:-251;520:-250;" }, { path: "755:-330;520:-330;" },
      { path: "755:-202;520:-202;" }
    ]
    controls.each do |change|
      expect(render_qea_route(**input.merge(change))).to eq(
        paths: ["M 382 362 L 295 234"],
        markers: ["382 362 372.24 356.54 370.76 345.46 380.51 350.92"]
      ), change.inspect
    end
    %w[0 1 3].each do |width|
      expect(render_qea_route(**input.merge(style: "TREE=V;LWidth=#{width};"))).to eq(
        paths: ["M 383 363 L 294 233"],
        markers: ["383 363 373.23 357.57 371.7 346.5 381.48 351.92"]
      ), width
    end
    expect(render_qea_route(**input.merge(connector_type: "Association"))).to eq(
      paths: ["M 383 363 L 294 233", "M 307.42 241.99 L 294 233 L 297.52 248.77"],
      markers: []
    )
  end
end
