# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  it "draws a direct line instead of replaying obsolete custom bends" do
    result = render_qea_route(path: "150:-250;450:-250;", style: "Mode=1;LWidth=2;")

    expect(result[:paths]).to eq(["M 211 239 L 358 141"])
  end

  it "clips a direct line through its stored endpoint anchors" do
    result = render_qea_route(
      source: [667, 305, 120, 80], target: [620, 45, 230, 125],
      path: "650:-230;699:-230;", style: "Mode=1;LWidth=2;",
      geometry: "SX=11;SY=40;EX=5;EY=-6;EDGE=1;"
    )

    expect(result[:paths]).to eq(["M 153 299 L 154 166"])
  end

  it "retains stored custom bends for other line modes" do
    %w[2 3].each do |mode|
      result = render_qea_route(path: "150:-250;450:-250;", style: "Mode=#{mode};LWidth=2;")

      expect(result[:paths]).to eq(["M 85 239 L 85 190 L 385 190 L 385 141"])
    end
  end

  it "keeps a lateral tree's outward source leg on the side edge" do
    result = render_qea_route(
      source: [826, 577, 340, 120], target: [670, 300, 229, 65],
      path: "784:-637;", style: "Mode=3;TREE=LV;LWidth=2;",
      geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;"
    )

    expect(result[:paths]).to eq(["M 191 377 L 149 377 L 149 105"])
    expect(result[:markers]).to eq(["149 105 155 116 143 116"])
  end

  it "retains top redocking for a vertical tree and an inward lateral bend" do
    [
      ["V", "784:-637;", "M 191 317 L 149 377 L 149 105"],
      ["LV", "900:-637;", "M 265 317 L 265 377 L 264 105"]
    ].each do |tree, path, expected|
      result = render_qea_route(
        source: [826, 577, 340, 120], target: [670, 300, 229, 65],
        path: path, style: "Mode=3;TREE=#{tree};LWidth=2;",
        geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;"
      )

      expect(result[:paths]).to eq([expected])
    end
  end
end
