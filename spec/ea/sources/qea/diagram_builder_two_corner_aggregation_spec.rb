# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  def saved_aggregation_points(**changes)
    points = nil
    render_qea_route(
      **{ connector_type: "Aggregation", source: [306, 231, 203, 125], target: [400, 591, 203, 121],
          path: "273:-342;273:-643;", style: "Mode=3;LWidth=2;",
          geometry: "SX=-102;SY=-49;EX=102;EY=7;EDGE=4;" }.merge(changes)
    ) do |document|
      points = document.diagrams.first.connectors.first.waypoints.map { |p| [p.position.x, p.position.y] }
    end
    points
  end

  it "preserves two saved aggregation corners and docks on both side outlines" do
    expect(saved_aggregation_points).to eq([[305, 342], [273, 342], [273, 643], [399, 643]])
  end

  it "preserves a two-corner aggregation whose trunk lies to the right" do
    expect(saved_aggregation_points(path: "700:-342;700:-643;"))
      .to eq([[510, 342], [700, 342], [700, 643], [604, 643]])
  end

  it "retains fallback behavior for absent, malformed, duplicate or zero-leg saved corners" do
    [nil, "junk273:-342;273:-643;", "273:-342;273:-342;",
     "305:-342;305:-643;", "399:-342;399:-643;"].each do |path|
      expect(saved_aggregation_points(path: path)).to eq([[400, 356], [400, 591]])
    end
  end
end
