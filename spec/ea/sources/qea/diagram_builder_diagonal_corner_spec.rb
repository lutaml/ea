# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:source) { [331, 370, 100, 80] }
  let(:target) { [540, 350, 100, 70] }

  it "preserves one authored diagonal bend and clips each stored origin leg on the outline" do
    cases = [
      ["SX=-50;SY=-23;EX=-31;EY=3;EDGE=4;", "508:-407;", "M 136 108 L 212 97 L 243 81"],
      ["SX=36;SY=-1;EX=-39;EY=26;EDGE=4;", "504:-383;", "M 136 96 L 208 73 L 243 55"]
    ]
    cases.each do |geometry, path, expected|
      result = render_qea_route(
        source: source, target: target, geometry: geometry, path: path,
        style: "Mode=3;LWidth=2;", connector_type: "Association",
        connector_attributes: { direction: "Unspecified" }
      )

      expect(result).to eq(paths: [expected], markers: [])
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:source) { [331, 370, 100, 80] }
  let(:target) { [540, 350, 100, 70] }

  [
    ["Mode=3;LWidth=0;", "Association", "508:-407;", "M 135 77 L 244 77"],
    ["Mode=1;LWidth=2;", "Association", "508:-407;", "M 136 100 L 243 76"],
    ["Mode=3;LWidth=2;TREE=OS;", "Association", "508:-407;", "M 135 97 L 212 97 L 244 97"],
    ["Mode=3;LWidth=2;", "Generalization", "508:-407;", "M 136 97 L 212 97 L 243 97"],
    ["Mode=3;LWidth=2;", "Aggregation", "508:-407;", "M 136 97 L 212 97 L 243 97"],
    ["Mode=3;LWidth=2;", "Association", "400:-407;", "M 136 77 L 243 77"]
  ].each do |style, type, path, expected|
    it "retains #{type} #{style} with #{path}" do
      result = render_qea_route(
        source: source, target: target, geometry: "SX=-50;SY=-23;EX=-31;EY=3;EDGE=4;",
        path: path, style: style, connector_type: type,
        connector_attributes: { direction: "Unspecified" }
      )

      expect(result[:paths]).to eq([expected])
    end
  end
end
