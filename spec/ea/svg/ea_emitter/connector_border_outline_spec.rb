# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock do
  include QeaRoutingHelpers

  let(:thin) do
    { connector_type: "Generalization", source: [724, 563, 384, 64],
      target: [761, 1, 312, 465], path: nil, geometry: "EDGE=1;",
      style: "Mode=3;LWidth=0;" }
  end
  let(:bordered) { "NSL=0;LCol=-1;LWth=2;BCol=16764159;" }
  let(:default) { "NSL=0;BCol=-1;BFol=-1;LCol=-1;LWth=-1;" }

  it "stops thin straight connectors on the outer edge of 2px element borders" do
    expect(render_qea_route(**thin, object_styles: [bordered, bordered])).to eq(
      paths: ["M 227 601 L 227 506"], markers: ["227 506 233 517 221 517"]
    )
    association = thin.merge(connector_type: "Association")
    expect(render_qea_route(**association, object_styles: [bordered, bordered])).to eq(
      paths: ["M 227 601 L 227 506", "M 233 521 L 227 506 L 221 521"], markers: []
    )
  end

  it "keeps default, absent, one-ended and legacy-width cases on their routes" do
    edge = { paths: ["M 227 602 L 227 505"], markers: ["227 505 233 516 221 516"] }
    cases = [
      ["default border", thin, [default, default], edge],
      ["no object style", thin, [nil, nil], edge],
      ["one end bordered", thin, [bordered, default], edge],
      ["border 0", thin, ["LWth=0;", "LWth=0;"], edge],
      ["tree V", thin.merge(style: "Mode=3;LWidth=0;TREE=V;"), [bordered, bordered], edge],
      ["connector width 2", thin.merge(style: "Mode=3;LWidth=2;"), [default, default],
       { paths: ["M 227 601 L 227 506"], markers: ["227 506 233 517 221 517"] }],
      ["unbordered association", thin.merge(connector_type: "Association"), [default, default],
       { paths: ["M 227 602 L 227 505", "M 233 520 L 227 505 L 221 520"], markers: [] }]
    ]

    cases.each do |name, input, styles, expected|
      expect(render_qea_route(**input, object_styles: styles)).to eq(expected), name
    end
  end
end
