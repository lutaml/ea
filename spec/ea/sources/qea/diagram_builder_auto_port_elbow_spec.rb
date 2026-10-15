# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:port_turn_route) do
    { source: [601, 300, 100, 97], target: [263, 370, 202, 110],
      geometry: "SX=-51;SY=20;EX=-102;EY=20;EDGE=4;", style: "Mode=2;LWidth=2;",
      path: nil, connector_type: "Association", connector_attributes: { direction: "Destination -> Source" } }
  end

  it "clips mathematical ports before adding the implicit Mode 2 corner", :aggregate_failures do
    result = render_qea_route(**port_turn_route) do |document|
      connector = document.diagrams.first.connectors.first
      expect(connector.style[:auto_port_elbow]).to be(true)
    end
    expect(result).to eq(paths: ["M 372 68 L 192 68 L 192 109", "M 357 74 L 372 68 L 357 62"], markers: [])
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:port_turn_route) do
    { source: [601, 300, 100, 97], target: [263, 370, 202, 110],
      geometry: "SX=-51;SY=20;EX=-102;EY=20;EDGE=4;", style: "Mode=2;LWidth=2;",
      path: nil, connector_type: "Association", connector_attributes: { direction: "Destination -> Source" } }
  end

  it "preserves other modes, widths, trees and authored paths" do
    cases = [
      [{ style: "Mode=1;LWidth=2;" }, "M 372 108 L 35 184"],
      [{ style: "Mode=3;LWidth=2;" }, "M 372 68 L 192 109"],
      [{ style: "Mode=2;TREE=V;LWidth=2;" }, "M 372 108 L 35 184"],
      [{ style: "Mode=2;LWidth=0;" }, "M 372 108 L 35 184"],
      [{ style: "Mode=2;LWidth=1;" }, "M 372 108 L 35 184"],
      [{ path: "540:-328;420:-328;" }, "M 372 108 L 35 184"]
    ]
    cases.each do |changes, expected|
      expect(render_qea_route(**port_turn_route.merge(changes))[:paths].first).to eq(expected), changes.inspect
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:port_turn_route) do
    { source: [601, 300, 100, 97], target: [263, 370, 202, 110],
      geometry: "SX=-51;SY=20;EX=-102;EY=20;EDGE=4;", style: "Mode=2;LWidth=2;",
      path: nil, connector_type: "Association", connector_attributes: { direction: "Destination -> Source" } }
  end

  it "preserves unphysical ports, shared rows and rays that hit the target side" do
    cases = [
      [{ geometry: "SX=-50;SY=20;EX=-102;EY=20;EDGE=4;" }, "M 373 108 L 35 184"],
      [{ geometry: "SX=-51;SY=20;EX=500;EY=20;EDGE=4;" }, "M 373 108 L 636 185"],
      [{ geometry: "SX=-51;SY=0;EX=-102;EY=0;EDGE=4;" }, "M 372 123 L 238 123"],
      [{ target: [263, 190, 202, 110] }, "M 372 218 L 35 115"]
    ]
    cases.each do |changes, expected|
      result = render_qea_route(**port_turn_route.merge(changes)) do |document|
        expect(document.diagrams.first.connectors.first.style[:auto_port_elbow]).to be_nil
      end
      expect(result[:paths].first).to eq(expected), changes.inspect
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:port_turn_route) do
    { source: [601, 300, 100, 97], target: [263, 370, 202, 110],
      geometry: "SX=-51;SY=20;EX=-102;EY=20;EDGE=4;", style: "Mode=2;LWidth=2;",
      path: nil, connector_type: "Association", connector_attributes: { direction: "Destination -> Source" } }
  end

  it "leaves an unplaced target without route geometry or SVG paths" do
    result = render_qea_route(**port_turn_route, target_placed: false) do |document|
      connector = document.diagrams.first.connectors.first
      expect(connector.waypoints).to be_empty
      expect(connector.target_anchor).to be_nil
      expect(connector.style[:auto_port_elbow]).to be_nil
    end
    expect(result).to eq(paths: [], markers: [])
  end
end
