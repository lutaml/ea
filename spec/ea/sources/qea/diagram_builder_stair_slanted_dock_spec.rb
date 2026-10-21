# frozen_string_literal: true

require "spec_helper"

# 30D62231 connector 601: the last leg of a stored stair aims at the saved
# target origin, so a bend row off the origin row docks on a slanted line.
RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:aggregation) do
    { connector_type: "Aggregation", source: [971, 1024, 120, 161], target: [263, 370, 202, 110],
      path: "215:-1111;215:-430;", geometry: "SX=8;SY=-8;EX=0;EY=0;EDGE=4;",
      style: "Mode=3;LWidth=2;" }
  end

  def waypoints_of(**change)
    connector = nil
    render_qea_route(**aggregation.merge(change)) { |document| connector = document.diagrams.first.connectors.first }
    connector.waypoints.map { |point| [point.position.x, point.position.y] }
  end

  it "slants the target dock toward the saved origin when the bend row is off the origin row" do
    expect(waypoints_of).to eq([[970, 1111], [215, 1111], [215, 430], [262, 428]])
  end

  it "keeps an orthogonal dock when the saved origin is on the bend row" do
    expect(waypoints_of(path: "215:-1111;215:-425;")).to eq([[970, 1111], [215, 1111], [215, 425], [262, 425]])
  end

  it "keeps an orthogonal dock when the saved target origin lies outside the target" do
    expect(waypoints_of(geometry: "SX=8;SY=-8;EX=-300;EY=0;EDGE=4;").last).to eq([262, 430])
  end
end
