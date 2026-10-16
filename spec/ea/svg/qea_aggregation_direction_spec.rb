# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA aggregation SVG markers" do
  include QeaRoutingHelpers

  it "keeps the target diamond and places reverse-direction arrow at the physical source" do
    marker_svg = nil
    svg = render_qea_route(path: "M 300,350 L 400,350", style: "",
                           source: [100, 300, 200, 100], target: [400, 300, 200, 100],
                           connector_type: "Aggregation",
                           connector_attributes: { destisaggregate: 1,
                                                   direction: "Destination -> Source" }) do |document|
      marker_svg = Ea::Svg::EaEmitter::Markers.new(
        document.diagrams.first, model_index: document.index_by_id
      ).render
    end

    expect(svg[:markers].length).to eq(1)
    expect(svg[:markers].first.split.first(2)).to eq(%w[335 90])
    expect(marker_svg.scan(/<polygon/).length).to eq(1)
    expect(marker_svg).to match(/M 315 294 L 300 300 L 315 306/)
  end
end
