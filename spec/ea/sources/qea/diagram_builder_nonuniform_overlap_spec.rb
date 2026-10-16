# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "moves a nonuniform horizontal route from the overlap midpoint by the stored source offset" do
    result = render_qea_route(source: [1186, 658, 108, 175], target: [736, 663, 261, 146],
                              geometry: "SX=1;SY=11;EX=0;EY=-8;EDGE=4;",
                              style: "Mode=2;LWidth=2;", path: nil, connector_type: "Association")

    expect(result).to eq(paths: ["M 484 107 L 297 107", "M 312 101 L 297 107 L 312 113"], markers: [])
  end
end
