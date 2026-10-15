# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "retains the certified square target and reclips the moved source on the saved axis" do
    cases = [
      [[330, 653, 180, 60], [360, 540, 130, 50], 423, "M 128 153 L 128 91"],
      [[541, 653, 181, 60], [551, 540, 149, 50], 626, "M 120 153 L 120 91"]
    ]
    cases.each do |source, target, axis, expected|
      connector = nil
      result = render_qea_route(source: source, target: target, path: nil,
                                style: "Mode=3;TREE=OS;LWidth=2;", connector_type: "Association",
                                geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;SCME=0;SCTR=0;",
                                connector_attributes: { ptstartx: axis, ptstarty: -640,
                                                        ptendx: axis, ptendy: -591 }) do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result[:paths].first).to eq(expected)
      expect(result[:markers]).to be_empty
      expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([axis, 653])
      expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([axis, 591])
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:square_link) do
    { source: [330, 653, 180, 60], target: [360, 540, 130, 50], path: nil,
      style: "Mode=3;TREE=OS;LWidth=2;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;",
      connector_type: "Association",
      connector_attributes: { ptstartx: 423, ptstarty: -640, ptendx: 423, ptendy: -591 } }
  end

  it "preserves stale, missing, nonvertical and already-current global coordinates" do
    controls = [
      { ptstarty: -653 }, { ptstarty: -591 }, { ptendy: -590 }, { ptendx: 424 },
      { ptstartx: 520, ptendx: 520 }, { ptstarty: nil }
    ]
    controls.each do |attributes|
      input = square_link.merge(connector_attributes: square_link[:connector_attributes].merge(attributes))
      expect(render_qea_route(**input)[:paths].first).to eq("M 126 153 L 128 90"), attributes.inspect
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "preserves omitted or nonzero offsets, other strokes, trees and stored bends" do
    input = { source: [330, 653, 180, 60], target: [360, 540, 130, 50], path: nil,
              style: "Mode=3;TREE=OS;LWidth=2;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;",
              connector_type: "Association",
              connector_attributes: { ptstartx: 423, ptstarty: -640, ptendx: 423, ptendy: -591 } }
    controls = [
      { geometry: "EX=0;EY=0;EDGE=1;" }, { geometry: "SX=0;SY=1;EX=0;EY=0;EDGE=1;" },
      { style: "Mode=3;TREE=V;LWidth=2;" }, { style: "Mode=3;TREE=OS;LWidth=0;" },
      { style: "Mode=3;TREE=OS;LWidth=1;" }, { path: "420:-630;425:-610;" }
    ]
    controls.each do |changes|
      expect(render_qea_route(**input.merge(changes))[:paths].first).to eq("M 126 153 L 128 90")
    end
  end
end
