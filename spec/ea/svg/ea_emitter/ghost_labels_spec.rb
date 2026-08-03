# frozen_string: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/ghost_labels"

RSpec.describe Ea::Svg::EaEmitter::GhostLabels do
  let(:ghost) do
    Ea::Model::GhostLabel.new(
      id: "g1",
      name: "_CityObject",
      end_kind: "source",
      anchor_x: 200,
      anchor_y: 100
    )
  end
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "dc1",
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ],
      ghost_labels: [ghost]
    )
  end
  let(:diagram) do
    Ea::Model::Diagram.new(id: "d1", name: "Test", connectors: [connector])
  end

  it "returns empty string when no ghost labels are present" do
    empty_connector = Ea::Model::DiagramConnector.new(id: "dc2", waypoints: [])
    diagram_with_none = Ea::Model::Diagram.new(id: "d2", name: "x",
                                               connectors: [empty_connector])
    expect(described_class.new(diagram_with_none).render).to eq("")
  end

  it "emits one italic <text> per ghost label" do
    svg = described_class.new(diagram).render
    expect(svg).to include(">_CityObject<")
    expect(svg).to include("font-style:italic")
    expect(svg.scan(/<text\b/).size).to eq(1)
  end

  it "skips hidden connectors' ghost labels" do
    hidden_connector = Ea::Model::DiagramConnector.new(
      id: "dc3", hidden: true, ghost_labels: [ghost],
      waypoints: []
    )
    diagram = Ea::Model::Diagram.new(id: "d3", name: "x",
                                     connectors: [hidden_connector])
    expect(described_class.new(diagram).render).to eq("")
  end
end
