# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "renders partial stored Association offsets through their original ray origins" do
    cases = [
      [[110, 180, 146, 80], [467, 15, 312, 465], "EX=-156;EY=27;EDGE=2;", "2",
       ["LWth=2;", "LWth=2;"], "M 182 245 L 391 245"],
      [[759, 174, 179, 80], [273, 46, 312, 465], "EX=156;EY=64;EDGE=4;", "2",
       ["LWth=2;", "LWth=2;"], "M 520 208 L 348 208"],
      [[570, 480, 404, 111], [660, 250, 100, 120], "SX=68;SY=54;EX=0;EY=0;EDGE=1;", "0",
       ["LWth=-1;", "LWth=-1;"], "M 304 270 L 220 160"],
      [[514, 291, 179, 76], [59, 10, 312, 465], "SX=-79;SY=12;EX=157;EY=-75;EDGE=4;", "0",
       ["LWth=2;", "LWth=2;"], "M 489 347 L 348 347"]
    ]

    cases.each do |input|
      source, target, geometry, width, object_styles, expected = input
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                style: "Mode=3;LWidth=#{width};", object_styles: object_styles,
                                path: nil, connector_type: "Association")
      expect(result[:paths].first).to eq(expected), geometry
      expect(result[:markers]).to be_empty
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:outline_ray) do
    { connector_type: "Association", source: [514, 291, 179, 76], target: [59, 10, 312, 465],
      geometry: "SX=-79;SY=12;EX=157;EY=-75;EDGE=4;", path: nil,
      style: "Mode=3;LWidth=0;", object_styles: ["LWth=2;", "LWth=2;"] }
  end

  it "requires explicit two-pixel borders at both ends to extend zero-width ray bounds" do
    [[nil, nil], ["LWth=0;", "LWth=0;"], ["LWth=-1;", "LWth=-1;"],
     ["LWth=2;", nil], [nil, "LWth=2;"]].each do |styles|
      result = render_qea_route(**outline_ray.merge(object_styles: styles))
      expect(result[:paths].first).to eq("M 490 359 L 348 197"), styles.inspect
    end
  end

  it "preserves other modes, trees, stroke widths and authored bends" do
    controls = [
      [{ style: "Mode=2;LWidth=0;" }, "M 489 358 L 348 197"],
      [{ style: "Mode=3;TREE=V;LWidth=0;" }, "M 490 359 L 348 197"],
      [{ style: "Mode=3;LWidth=1;" }, "M 490 359 L 348 197"],
      [{ path: "480:-315;400:-317;" }, "M 490 345 L 456 345 L 376 347 L 347 347"]
    ]
    controls.each do |changes, expected|
      expect(render_qea_route(**outline_ray.merge(changes))[:paths].first).to eq(expected)
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "does not mark default center offsets as an explicit stored ray" do
    connector = nil
    result = render_qea_route(connector_type: "Association", source: [514, 291, 179, 76],
                              target: [59, 10, 312, 465], path: nil, style: "Mode=3;LWidth=0;",
                              geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;",
                              object_styles: ["LWth=2;", "LWth=2;"]) do |document|
      connector = document.diagrams.first.connectors.first
    end

    expect(result[:paths].first).to eq("M 489 338 L 348 307")
    expect(connector.style[:stored_association_ray]).to be_nil
    expect(connector.style[:association_ray_outline]).to be_nil
  end
end
