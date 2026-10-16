# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "preserves distinct authored bends on thin vertical Association trees" do
    cases = [
      ["221:-660;217:-660;", "SX=-3;SY=-32;EX=0;EY=0;EDGE=3;", 156],
      ["164:-660;217:-660;", "SX=-59;SY=2;EX=0;EY=0;EDGE=3;", 99],
      ["250:-660;217:-660;", "SX=27;SY=-1;EX=0;EY=0;EDGE=3;", 185],
      ["192:-660;217:-660;", "SX=-31;SY=-3;EX=0;EY=0;EDGE=3;", 127]
    ]
    cases.each do |path, geometry, dock_x|
      result = render_qea_route(
        connector_type: "Association", source: [100, 260, 250, 270], target: [40, 710, 355, 90],
        path: path, geometry: geometry, style: "Mode=3;TREE=V;LWidth=0;",
        connector_attributes: { direction: "Unspecified" }
      )

      expect(result[:paths]).to eq(["M #{dock_x + 60} 310 L #{dock_x + 60} 440 L 212 440 L 212 490"])
    end
  end
end
