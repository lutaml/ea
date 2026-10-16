# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "docks explicitly stored zero-offset horizontal origins on the stroked outlines" do
    cases = [
      [[1110, 501, 181, 80], [840, 501, 170, 80], "M 304 80 L 206 80"],
      [[1332, 380, 118, 80], [1010, 380, 153, 80], "M 356 80 L 189 80"]
    ]
    cases.each do |source, target, expected|
      result = render_qea_route(
        connector_type: "Association", source: source, target: target, path: nil,
        style: "Mode=3;LWidth=2;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;",
        connector_attributes: { direction: "Unspecified" }
      )

      expect(result[:paths]).to eq([expected])
    end
  end

  it "uses the same stored-center rule for a vertical zero-offset ray" do
    result = render_qea_route(
      connector_type: "Association", source: [380, 1332, 80, 118], target: [380, 1010, 80, 153], path: nil,
      style: "Mode=3;LWidth=2;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;",
      connector_attributes: { direction: "Unspecified" }
    )

    expect(result[:paths]).to eq(["M 75 361 L 75 194"])
  end
end
