# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Connectors do
  let(:diagram) do
    Ea::Model::Diagram.new(
      id: "d1", name: "D",
      connectors: [
        Ea::Model::DiagramConnector.new(
          id: "c1",
          waypoints: [
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 100))
          ]
        )
      ]
    )
  end

  it "emits a single <g> wrapping all connector paths" do
    out = described_class.new(diagram).render
    expect(out.scan(/<g\b/).size).to eq(1)
    expect(out).to include("<path d=\"M 0 0 L 100 100\"")
  end

  it "skips hidden connectors" do
    diagram.connectors.first.hidden = true
    out = described_class.new(diagram).render
    expect(out).to eq("")
  end
end
