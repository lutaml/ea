# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "seats nonuniform Mode 2 associations at the stored source mathematical row", :aggregate_failures do
    cases = [
      [[644, 154, 181, 80], [270, 150, 200, 150], "SX=8;SY=-4;EX=15;EY=-33;EDGE=4;",
       ["M 408 88 L 236 88", "M 251 82 L 236 88 L 251 94"]],
      [[258, 377, 179, 80], [581, 226, 312, 465], "SX=9;SY=-1;EX=9;EY=-2;EDGE=2;",
       ["M 215 232 L 357 232", "M 342 238 L 357 232 L 342 226"]],
      [[818, 378, 190, 80], [346, 190, 343, 445], "SX=172;SY=-8;EX=45;EY=-7;EDGE=4;",
       ["M 506 276 L 379 276", "M 394 270 L 379 276 L 394 282"]]
    ]
    cases.each do |source, target, geometry, paths|
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                style: "Mode=2;LWidth=2;", path: nil, connector_type: "Association")
      expect(result).to eq(paths: paths, markers: []), geometry
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:source_row_route) do
    { source: [644, 154, 181, 80], target: [270, 150, 200, 150],
      geometry: "SX=8;SY=-4;EX=15;EY=-33;EDGE=4;", style: "Mode=2;LWidth=2;",
      path: nil, connector_type: "Association" }
  end

  it "preserves other modes, tree routing, line widths and custom paths" do
    cases = [
      [{ style: "Mode=3;LWidth=2;" }, "M 408 104 L 236 133"],
      [{ style: "Mode=1;LWidth=2;" }, "M 409 80 L 235 81"],
      [{ style: "Mode=2;TREE=V;LWidth=2;" }, "M 409 80 L 235 81"],
      [{ style: "Mode=2;LWidth=0;" }, "M 409 80 L 235 81"],
      [{ style: "Mode=2;LWidth=1;" }, "M 409 80 L 235 81"],
      [{ path: "600:-300;" }, "M 409 80 L 235 81"]
    ]
    cases.each do |changes, expected|
      expect(render_qea_route(**source_row_route.merge(changes))[:paths].first).to eq(expected), changes.inspect
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:source_row_route) do
    { source: [644, 154, 181, 80], target: [270, 150, 200, 150],
      geometry: "SX=8;SY=-4;EX=15;EY=-33;EDGE=4;", style: "Mode=2;LWidth=2;",
      path: nil, connector_type: "Association" }
  end

  it "preserves incomplete offsets, wrong facing edges and rows outside either box" do
    cases = [
      [{ geometry: "SX=8;SY=-4;EX=15;EDGE=4;" }, "M 409 89 L 235 106"],
      [{ geometry: "SX=8;SY=-4;EX=15;EY=-33;EDGE=2;" }, "M 580 124 L 169 124 L 169 190"],
      [{ geometry: "SX=8;SY=500;EX=15;EY=-33;EDGE=4;" }, "M 507 584 L 226 190"],
      [{ target: [270, 400, 200, 150] }, "M 444 120 L 209 286"]
    ]
    cases.each do |changes, expected|
      expect(render_qea_route(**source_row_route.merge(changes))[:paths].first).to eq(expected), changes.inspect
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "preserves the established overlap midpoint for equal source and target offsets" do
    result = render_qea_route(source: [1186, 658, 108, 175], target: [736, 663, 261, 146],
                              geometry: "SX=1;SY=55;EX=-51;EY=55;EDGE=4;",
                              style: "Mode=2;LWidth=2;", path: nil, connector_type: "Association")
    expect(result).to eq(paths: ["M 484 63 L 297 63", "M 312 57 L 297 63 L 312 69"], markers: [])
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "keeps links to an unplaced target invisible without trying to derive its route" do
    result = render_qea_route(source: [644, 154, 181, 80], target: [270, 150, 200, 150],
                              geometry: "SX=8;SY=-4;EX=15;EY=-33;EDGE=4;",
                              style: "Mode=2;LWidth=2;", path: nil,
                              connector_type: "Association", target_placed: false) do |document|
      connector = document.diagrams.first.connectors.first
      expect(connector.waypoints).to be_empty
      expect(connector.target_anchor).to be_nil
    end
    expect(result).to eq(paths: [], markers: [])
  end
end
