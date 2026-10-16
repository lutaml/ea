# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "keeps an empty direct Association on its aligned stored mathematical origins" do
    result = render_qea_route(source: [1009, 424, 179, 131], target: [296, 252, 287, 465],
                              geometry: "SX=-86;SY=15;EX=144;EY=10;EDGE=4;",
                              style: "Mode=1;LWidth=2;", path: nil, connector_type: "Association",
                              connector_attributes: { direction: "Unspecified" })

    expect(result[:paths]).to eq(["M 747 262 L 323 262"])
  end
end
