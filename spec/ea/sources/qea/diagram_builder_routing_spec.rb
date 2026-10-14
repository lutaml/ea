# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  it "offsets only width-2 parent-above multi-bend routes, preserving interior bends" do # rubocop:disable Metrics/BlockLength
    cases = [
      [{ path: "150:-250;450:-250;", style: "TREE=V;LWidth=2;" },
       "M 85 239 L 85 190 L 385 190 L 385 141"],
      [{ path: "150:-270;250:-270;250:-230;450:-230;", style: "TREE=V;LWidth=2;" },
       "M 85 239 L 85 210 L 185 210 L 185 170 L 385 170 L 385 141"],
      [{ path: "450:-350;", style: "TREE=LV;LWidth=2;",
         geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=2;" },
       "M 235 290 L 385 290 L 385 140"],
      [{ path: "450:-250;", style: "LWidth=2;" },
       "M 235 240 L 385 190 L 385 140"],
      [{ path: "150:-250;450:-250;", style: "TREE=V;LWidth=2;",
         source: [100, 100, 200, 100], target: [400, 300, 200, 100] },
       "M 135 40 L 85 190 L 385 190 L 435 240"],
      [{ path: "", style: "TREE=V;LWidth=2;" }, "M 210 240 L 360 140"]
    ]
    ["0", "1", "3", "2.0", nil].each do |width|
      style = width ? "TREE=V;LWidth=#{width};" : "TREE=V;"
      cases << [{ path: "150:-250;450:-250;", style: style },
                "M 85 240 L 85 190 L 385 190 L 385 140"]
    end

    cases.each do |input, expected|
      result = render_qea_route(**input)

      expect(result[:paths]).to eq([expected]), "route input: #{input.inspect}"
    end
  end

  it "moves the marker tip with the target and preserves the triangle dimensions" do
    result = render_qea_route(path: "150:-250;450:-250;", style: "TREE=V;LWidth=2;")

    expect(result[:markers]).to eq(["385 141 391 152 379 152"])
  end
end
