# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "uses mathematical Y offsets for a direct Association's stored ray" do
    result = render_qea_route(
      connector_type: "Association", source: [764, 461, 179, 107], target: [193, 426, 365, 240],
      path: "435:-1012;198:-1012;", style: "Mode=1;LWidth=2;",
      geometry: "SX=17;SY=50;EX=-75;EY=19;EDGE=4;",
      connector_attributes: { direction: "Unspecified" }
    )

    expect(result[:paths]).to eq(["M 605 89 L 401 112"])
  end

  it "preserves the sign of negative stored Y offsets" do
    result = render_qea_route(
      connector_type: "Association", source: [764, 461, 179, 107], target: [193, 426, 365, 240],
      path: "434:-1012;325:-1035;", style: "Mode=1;LWidth=2;",
      geometry: "SX=-35;SY=-7;EX=-32;EY=-38;EDGE=4;",
      connector_attributes: { direction: "Unspecified" }
    )

    expect(result[:paths]).to eq(["M 605 142 L 401 169"])
  end
end
