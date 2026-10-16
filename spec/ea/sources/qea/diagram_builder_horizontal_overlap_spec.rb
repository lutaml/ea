# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "seats a rightward Mode 2 Association at the shared vertical midpoint" do
    result = render_qea_route(
      connector_type: "Association", source: [350, 241, 100, 210], target: [620, 251, 387, 173],
      path: nil, style: "Mode=2;LWidth=2;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=2;",
      connector_attributes: { direction: "Unspecified" }
    )

    expect(result[:paths]).to eq(["M 136 136 L 304 136"])
  end

  it "replaces an implicit corner with the shared overlap ray" do
    result = render_qea_route(
      connector_type: "Association", source: [410, 280, 101, 161], target: [929, 291, 192, 150],
      path: nil, style: "Mode=2;LWidth=2;", geometry: "SX=6;SY=6;EX=6;EY=6;EDGE=2;",
      connector_attributes: { direction: "Unspecified" }
    )

    expect(result[:paths]).to eq(["M 137 120 L 553 120"])
  end

  it "moves implicit overlap rays by either sign of the shared Y offset" do
    cases = [
      ["SX=10;SY=59;EX=10;EY=59;EDGE=2;", "M 137 67 L 553 67"],
      ["SX=0;SY=-40;EX=0;EY=-40;EDGE=2;", "M 137 166 L 553 166"]
    ]
    cases.each do |geometry, expected|
      result = render_qea_route(
        connector_type: "Association", source: [410, 280, 101, 161], target: [929, 291, 192, 150],
        path: nil, style: "Mode=2;LWidth=2;", geometry: geometry,
        connector_attributes: { direction: "Unspecified" }
      )

      expect(result[:paths]).to eq([expected]), geometry
    end
  end
end
