# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "recomputes stale horizontal Mode 2 jogs outside both boxes at the source row" do
    cases = [
      ["358:-940;112:-940;", "SX=-34;SY=-40;EX=-12;EY=-8;EDGE=4;", "M 614 137 L 401 137"],
      ["357:-940;146:-940;", "SX=-29;SY=-10;EX=34;EY=100;EDGE=4;", "M 614 107 L 401 107"]
    ]
    cases.each do |path, geometry, expected|
      result = render_qea_route(
        connector_type: "Association", source: [696, 354, 194, 115], target: [116, 354, 365, 240],
        path: path, style: "Mode=2;LWidth=2;", geometry: geometry,
        connector_attributes: { direction: "Unspecified" }
      )

      expect(result[:paths]).to eq([expected]), geometry
    end
  end

  it "keeps a Mode 3 Association's authored horizontal trunk between separated boxes" do
    result = render_qea_route(
      connector_type: "Association", source: [811, 851, 146, 80], target: [815, 444, 235, 156],
      path: "837:-635;855:-635;", style: "Mode=3;LWidth=2;",
      geometry: "SX=-47;SY=0;EX=-77;EY=-1;EDGE=1;",
      connector_attributes: { direction: "Unspecified" }
    )

    expect(result[:paths]).to eq(["M 61 446 L 61 231 L 79 231 L 79 197"])
  end

  it "keeps a Mode 3 Association's authored vertical trunk outside both boxes" do
    result = render_qea_route(
      connector_type: "Association", source: [600, 300, 100, 100], target: [100, 100, 100, 100],
      path: "800:-350;800:-150;", style: "Mode=3;LWidth=2;",
      geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;",
      connector_attributes: { direction: "Unspecified" }
    )

    expect(result[:paths]).to eq(["M 636 290 L 735 290 L 735 90 L 136 90"])
  end
end
