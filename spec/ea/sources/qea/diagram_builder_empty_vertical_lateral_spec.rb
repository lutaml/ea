# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "derives a flush vertical lateral corner when the authored Path is empty" do
    result = render_qea_route(
      connector_type: "Association", source: [610, 720, 153, 80], target: [630, 260, 268, 258],
      path: nil, style: "Mode=3;TREE=LV;LWidth=0;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=3;",
      connector_attributes: { direction: "Destination -> Source" }
    )

    expect(result[:paths].first).to eq("M 188 540 L 189 540 L 189 298")
  end

  it "keeps an explicit vertical lateral corner" do
    result = render_qea_route(
      connector_type: "Association", source: [100, 260, 250, 270], target: [410, 720, 100, 80],
      path: "460:-395;", style: "Mode=3;TREE=LV;LWidth=0;",
      geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=2;"
    )

    expect(result[:paths].first).to eq("M 285 175 L 395 175 L 395 500")
  end
end
