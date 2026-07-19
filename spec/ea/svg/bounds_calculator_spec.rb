# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::BoundsCalculator do
  it "unions element rects and waypoint points" do
    diagram = Ea::Model::Diagram.new(
      id: "d1",
      name: "D",
      elements: [
        Ea::Model::DiagramElement.new(
          id: "de1",
          bounds: Ea::Model::Bounds.new(x: 100, y: 100, width: 200, height: 80)
        )
      ],
      connectors: [
        Ea::Model::DiagramConnector.new(
          id: "dc1",
          waypoints: [
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 500, y: 500))
          ]
        )
      ]
    )

    b = described_class.new(diagram).compute
    expect(b.x).to eq(0)
    expect(b.y).to eq(0)
    expect(b.width).to eq(500)
    expect(b.height).to eq(500)
  end

  it "normalizes inverted (negative-height) element rects" do
    diagram = Ea::Model::Diagram.new(
      id: "d1",
      name: "D",
      elements: [
        Ea::Model::DiagramElement.new(
          id: "de1",
          bounds: Ea::Model::Bounds.new(x: 0, y: 100, width: 50, height: -80)
        )
      ]
    )

    b = described_class.new(diagram).compute
    expect(b.y).to eq(20)
    expect(b.height).to eq(80)
  end

  it "falls back to diagram bounds when no elements or connectors" do
    diagram = Ea::Model::Diagram.new(
      id: "d1", name: "D",
      bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 500, height: 300)
    )

    b = described_class.new(diagram).compute
    expect(b.width).to eq(500)
    expect(b.height).to eq(300)
  end
end
