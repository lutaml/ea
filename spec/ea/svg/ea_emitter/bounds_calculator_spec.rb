# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::BoundsCalculator do
  let(:diagram_with_bounds) do
    Ea::Model::Diagram.new(
      id: "d1", name: "Test",
      elements: [
        Ea::Model::DiagramElement.new(
          id: "e1",
          bounds: Ea::Model::Bounds.new(x: 100, y: 100, width: 200, height: 80),
          image_bounds: Ea::Model::Bounds.new(x: 105, y: 110, width: 200, height: 90)
        ),
        Ea::Model::DiagramElement.new(
          id: "e2",
          bounds: Ea::Model::Bounds.new(x: 500, y: 200, width: 100, height: 80)
        )
      ]
    )
  end

  it "uses logical bounds for x-extent" do
    out = described_class.new(diagram_with_bounds).compute
    expect(out[0]).to eq(100) # min_x from bounds.x
  end

  it "extends y-extent via image_bounds union" do
    out = described_class.new(diagram_with_bounds).compute
    # element 1 image bottom = 110 + 90 = 200; element 2 bounds bottom = 280
    # max y = 280, min y = 100, height = 180 + INSET_TOP(40) + INSET_BOTTOM(57) = 277
    expect(out[3]).to eq(277)
  end

  it "includes marker extent around connector endpoints" do
    diagram = Ea::Model::Diagram.new(
      id: "d2", name: "Conn",
      elements: [
        Ea::Model::DiagramElement.new(
          id: "e1",
          bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 100, height: 50)
        )
      ],
      connectors: [
        Ea::Model::DiagramConnector.new(
          id: "c1",
          waypoints: [
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 50, y: 25)),
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 200, y: 25))
          ]
        )
      ]
    )
    out = described_class.new(diagram).compute
    # connector goes to x=200, marker extent adds 15 → max_x = 215
    # width = 215 - 0 + INSET_LEFT(35) + INSET_RIGHT(50) = 300
    expect(out[2]).to eq(300)
  end

  it "returns minimal canvas for empty diagram" do
    out = described_class.new(Ea::Model::Diagram.new(id: "x", name: "x")).compute
    expect(out).to eq([0, 0, 1, 1])
  end
end
