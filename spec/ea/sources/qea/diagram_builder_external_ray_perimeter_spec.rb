# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "selects the right perimeter crossing before the bottom crossing for an external source" do
    result = render_qea_route(source: [175, 627, 160, 51], target: [480, 460, 276, 224],
                              geometry: "SX=-139;SY=-85;EX=6;EY=-5;EDGE=4;",
                              style: "Mode=3;LWidth=2;", path: nil, connector_type: "Association",
                              connector_attributes: { direction: "Destination -> Source" })
    expect(result[:paths].first).to eq("M 196 247 L 339 202")
    expect(result[:markers]).to be_empty
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "preserves the native top, right and bottom crossings in other external-source layouts" do
    cases = [
      [[831, 398, 130, 80], [643, 540, 276, 224], "SX=98;SY=113;EX=-15;EY=-35;EDGE=1;",
       "M 340 39 L 251 181"],
      [[647, 262, 118, 80], [489, 457, 276, 224], "SX=87;SY=112;EX=8;EY=-8;EDGE=1;",
       "M 310 39 L 230 234"],
      [[582, 652, 160, 51], [177, 519, 276, 224], "SX=139;SY=-45;EX=34;EY=-1;EDGE=2;",
       "M 568 225 L 312 173"],
      [[597, 650, 141, 70], [218, 544, 276, 224], "SX=137;SY=-22;EX=13;EY=7;EDGE=2;",
       "M 556 194 L 312 161"],
      [[461, 1010, 100, 80], [374, 772, 210, 190], "SX=24;SY=-95;EX=-8;EY=40;EDGE=1;",
       "M 168 277 L 159 231"],
      [[604, 904, 160, 51], [185, 773, 276, 224], "SX=139;SY=-45;EX=34;EY=-1;EDGE=2;",
       "M 577 223 L 312 172"]
    ]
    cases.each do |source, target, geometry, expected|
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                style: "Mode=3;LWidth=2;", path: nil, connector_type: "Association",
                                connector_attributes: { direction: "Destination -> Source" })
      expect(result[:paths].first).to eq(expected), geometry
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:external_perimeter_route) do
    { source: [175, 627, 160, 51], target: [480, 460, 276, 224],
      geometry: "SX=-139;SY=-85;EX=6;EY=-5;EDGE=4;", style: "Mode=3;LWidth=2;",
      path: nil, connector_type: "Association" }
  end

  it "preserves unsupported styles, authored paths and source origins inside their outline" do
    cases = [
      [{ style: "Mode=2;LWidth=2;" }, "M -24 147 L 340 147"],
      [{ style: "Mode=3;LWidth=0;" }, "M -24 147 L 340 147"],
      [{ style: "Mode=3;LWidth=1;" }, "M -24 147 L 340 147"],
      [{ path: "400:-650;" }, "M -24 147 L 339 147"],
      [{ geometry: "SX=0;SY=0;EX=6;EY=-5;EDGE=4;" }, "M 196 215 L 339 186"]
    ]
    cases.each do |changes, expected|
      expect(render_qea_route(**external_perimeter_route.merge(changes))[:paths].first).to eq(expected), changes.inspect
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock do
  include ConnectorRedockHelpers

  it "retains the nearest crossing for a custom model without the producer marker" do
    fixture = redock_fixture(type: "Association", source: [175, 627, 160, 51],
                             target: [480, 460, 276, 224], style: { mode: "3" },
                             anchors: [[116, 737], [624, 577]])
    expect(redock_output(fixture).first).to eq(["M 303 678 L 480 622"])
  end
end
