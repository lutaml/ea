# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

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

  it "keeps the native 16-unit depth and 12-unit base in every orientation" do
    [[100, 0], [-100, 0], [0, 100], [0, -100], [100, 100], [-100, -100]].each do |base|
      polygon = Nokogiri::XML.fragment(renderer.triangle_polygon([0, 0], base)).at_css("polygon")
      points = polygon["points"].split.map(&:to_f).each_slice(2).to_a
      length = Math.hypot(*base)
      ux, uy = base.map { |value| value / length }

      expect(points.first).to eq([0, 0])
      expect(points.drop(1).map { |x, y| x * ux + y * uy }).to all(be_within(0.01).of(16))
      offsets = points.drop(1).map { |x, y| -x * uy + y * ux }.sort
      expect(offsets).to match([-6.0, 6.0].map { |value| be_within(0.01).of(value) })
    end
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
          fragment = Nokogiri::XML.fragment(renderer.render)
          polygon = fragment.at_css("polygon")
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
      fragment = Nokogiri::XML.fragment(renderer.render)
      polygon = fragment.at_css(tag)

      expect(polygon["points"].split.map(&:to_f)).to eq([0, 0, 10, -5, 20, 0, 10, 5])
      expect(polygon.parent["style"]).to include(style, "stroke-width:4;")
    end
    { "Association" => "M 85 6 L 100 0 L 85 -6", "Dependency" => "M 85 5 L 100 0 L 85 -5" }.each do |type, path|
      connector.connector_type = type
      fragment = Nokogiri::XML.fragment(renderer.render)

      expect(fragment.at_css("path")["d"]).to eq(path)
      expect(fragment.at_css("path").parent["style"]).to include("fill-opacity:0.00", "stroke-width:4;")
      expect(fragment.css("polygon")).to be_empty
    end
  end
end
