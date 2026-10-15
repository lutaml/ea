# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "clips crossing Association rays whose stored source origins lie outside the source box" do
    cases = [
      [[582, 652, 160, 51], [177, 519, 276, 224], "EDGE=2;SX=139;SY=-45;EX=34;EY=-1;",
       "M 568 225 L 312 173"],
      [[647, 262, 118, 80], [489, 457, 276, 224], "EDGE=1;SX=87;SY=112;EX=8;EY=-8;",
       "M 310 39 L 230 234"],
      [[597, 650, 141, 70], [218, 544, 276, 224], "EDGE=2;SX=137;SY=-22;EX=13;EY=7;",
       "M 556 194 L 312 161"],
      [[604, 904, 160, 51], [185, 773, 276, 224], "EDGE=2;SX=139;SY=-45;EX=34;EY=-1;",
       "M 577 223 L 312 172"],
      [[831, 398, 130, 80], [643, 540, 276, 224], "EDGE=1;SX=98;SY=113;EX=-15;EY=-35;",
       "M 340 39 L 251 181"]
    ]
    cases.each do |source, target, geometry, expected|
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                style: "Mode=3;LWidth=2;", path: nil, connector_type: "Association")
      expect(result[:paths].first).to eq(expected), geometry
      expect(result[:markers]).to be_empty
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:external_source_ray) do
    { connector_type: "Association", source: [582, 652, 160, 51], target: [177, 519, 276, 224],
      geometry: "EDGE=2;SX=139;SY=-45;EX=34;EY=-1;", path: nil, style: "Mode=3;LWidth=2;" }
  end

  it "preserves unsupported borders, target origins, noncrossing rays and authored routing" do
    cases = [
      [{ style: "Mode=3;LWidth=0;" }, "M 599 224 L 311 224 L 311 156"],
      [{ geometry: "EDGE=2;SX=139;SY=-45;EX=500;EY=-1;" }, "M 599 224 L 311 224 L 311 152"],
      [{ geometry: "EDGE=2;SX=139;SY=300;EX=34;EY=-1;" }, "M 532 173 L 311 173 L 311 156"],
      [{ style: "Mode=2;LWidth=2;" }, "M 599 224 L 311 224 L 311 156"],
      [{ style: "Mode=3;TREE=V;LWidth=2;" }, "M 599 224 L 311 224 L 311 156"],
      [{ style: "Mode=3;LWidth=1;" }, "M 599 224 L 311 224 L 311 156"],
      [{ path: "550:-675;470:-632;" }, "M 599 224 L 408 196 L 328 153 L 311 156"]
    ]
    cases.each do |changes, expected|
      connector = nil
      result = render_qea_route(**external_source_ray.merge(changes)) do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result[:paths].first).to eq(expected), changes.inspect
      expect(connector.style[:stored_association_ray]).to be_nil
    end
  end
end
