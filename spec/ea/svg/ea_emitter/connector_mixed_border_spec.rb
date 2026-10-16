# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock do
  include QeaRoutingHelpers

  let(:route) do
    { source: [67, 378, 126, 254], target: [470, 385, 260, 240],
      geometry: "SX=-21;SY=-108;EX=-21;EY=-111;EDGE=2;",
      style: "Mode=2;LWidth=2;", path: nil, connector_type: "Association",
      connector_attributes: { direction: "Unspecified" } }
  end

  it "clips each end using its explicit element border width" do
    expect(render_qea_route(**route, object_styles: ["LWth=0;", "LWth=2;"])).to eq(
      paths: ["M 161 275 L 437 275"], markers: []
    )
    direct = route.merge(geometry: "SX=2;SY=84;EX=-130;EY=84;EDGE=2;", style: "Mode=3;LWidth=2;")
    expect(render_qea_route(**direct, object_styles: ["LWth=0;", "LWth=2;"])).to eq(
      paths: ["M 161 83 L 437 83"], markers: []
    )
  end

  it "preserves the outer stroke docking for explicit and inherited two-pixel borders" do
    [["LWth=2;", "LWth=2;"], [nil, nil], ["LWth=-1;", "LWth=-1;"]].each do |styles|
      expect(render_qea_route(**route, object_styles: styles)).to eq(
        paths: ["M 162 275 L 437 275"], markers: []
      )
    end
  end
end
