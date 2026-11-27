# frozen_string_literal: true

require "spec_helper"
require "moxml"

RSpec.shared_context "native triangle dimensions" do
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "triangle", connector_type: "Generalization",
      direction: "Source -> Destination", style: { lwidth: 4 },
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
  end
  let(:diagram) { Ea::Model::Diagram.new(id: "diagram", connectors: [connector]) }
  let(:renderer) { Ea::Svg::EaEmitter::Markers.new(diagram, model_index: {}) }
end

RSpec.describe Ea::Svg::EaEmitter::Markers do
  include_context "native triangle dimensions"

  it "keeps native whole-pixel vertices at each triangle orientation" do
    {
      [100, 0] => [[16, -6], [16, 6]], [-100, 0] => [[-16, 6], [-16, -6]],
      [0, 100] => [[6, 16], [-6, 16]], [0, -100] => [[-6, -16], [6, -16]],
      [100, 100] => [[16, 7], [7, 16]], [-100, -100] => [[-16, -7], [-7, -16]]
    }.each do |base, vertices|
      polygon = Moxml.parse("<root>#{renderer.triangle_polygon([0, 0], base)}</root>").at_xpath("//*[local-name()='polygon']")
      points = polygon["points"].split.map(&:to_f).each_slice(2).to_a

      expect(points).to eq([[0, 0], *vertices])
    end
  end

  it "matches source connector 702's native near-vertical triangle vertices" do
    polygon = Moxml.parse("<root>#{renderer.triangle_polygon([850, 422], [851, 460])}</root>").at_xpath("//*[local-name()='polygon']")

    expect(polygon["points"].split.map(&:to_f)).to eq([850, 422, 856, 438, 844, 438])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Markers do
  include_context "native triangle dimensions"

  it "retains white fill, endpoint selection and explicit pen width for triangle kinds" do
    %w[Generalization Realization Realisation].each do |type|
      connector.connector_type = type
      ["Source -> Destination", "Destination -> Source"].each do |direction|
        connector.direction = direction
        [1, 4].each do |width|
          connector.style = { lwidth: width }
          fragment = Moxml.parse("<root>#{renderer.render}</root>")
          polygon = fragment.at_xpath("//*[local-name()='polygon']")
          expected = direction == "Source -> Destination" ? [100, 0, 84, 6, 84, -6] : [0, 0, 16, -6, 16, 6]

          expect(polygon["points"].split.map(&:to_f)).to eq(expected)
          expect(polygon.parent["style"]).to include("fill:#FFFFFF;fill-opacity:1.00", "stroke-width:#{width};")
        end
      end
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Markers do
  include_context "native triangle dimensions"

  it "preserves filled and hollow diamonds and open arrows" do
    {
      "Composition" => ["polygon", "fill:#000000;fill-opacity:1.00"],
      "Aggregation" => ["polygon", "fill:#FFFFFF;fill-opacity:1.00"]
    }.each do |type, (tag, style)|
      connector.connector_type = type
      fragment = Moxml.parse("<root>#{renderer.render}</root>")
      polygon = fragment.at_xpath("//*[local-name()='#{tag}']")

      expect(polygon["points"].split.map(&:to_f)).to eq([0, 0, 10, -5, 20, 0, 10, 5])
      expect(polygon.parent["style"]).to include(style, "stroke-width:4;")
    end
    { "Association" => "M 85 6 L 100 0 L 85 -6", "Dependency" => "M 85 5 L 100 0 L 85 -5" }.each do |type, path|
      connector.connector_type = type
      fragment = Moxml.parse("<root>#{renderer.render}</root>")

      expect(fragment.at_xpath("//*[local-name()='path']")["d"]).to eq(path)
      expect(fragment.at_xpath("//*[local-name()='path']").parent["style"]).to include("fill-opacity:0.00", "stroke-width:4;")
      expect(fragment.xpath("//*[local-name()='polygon']")).to be_empty
    end
  end
end
