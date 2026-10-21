# frozen_string_literal: true

require "spec_helper"

RSpec.shared_context "opening source-context bridges" do
  let(:fixture_directory) { fixtures_path("issue135_route_style") }
  let(:document) do
    Ea::Sources::Xmi::Adapter.from_path(File.join(fixture_directory, "opening-bridge-context.xmi"))
  end
  let(:diagram) { document.diagrams.first }
  let(:emitter) { Ea::Svg::EaEmitter::Connectors.new(diagram, model_index: document.index_by_id) }
  let(:routes) do
    diagram.connectors.select(&:renderable?).filter_map do |connector|
      points = emitter.send(:resolved_points, connector)
      [connector, points] if points.size >= 2
    end
  end
  let(:opening) do
    diagram.connectors.find { |connector| connector.relationship_ref == "EAID_7C5F9D22_2C12_418b_B3A2_BCA11BAC2361" }
  end
  let(:points) { routes.find { |connector, _route| connector.equal?(opening) }.last }
  let(:bridges) { Ea::Svg::EaEmitter.const_get(:ConnectorBridges).new(diagram, routes) }
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "opening serialization preservation" do
  include_context "opening source-context bridges"

  it "retains the complete opening connector when its original crossing context is restored" do
    reduced = Ea::Sources::Xmi::Adapter.from_path(
      File.join(fixture_directory, "property-source-146-629-opening.xmi")
    ).diagrams.first.connectors.find { |connector| connector.relationship_ref == opening.relationship_ref }
    before = opening.to_yaml

    expect(before).to eq(reduced.to_yaml)
    expect(points).to eq([[432, 1157], [970, 1158]])
    bridges.path_for(opening, points)
    expect(opening.to_yaml).to eq(before)
    expect(points).to eq([[432, 1157], [970, 1158]])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "opening native arc acceptance" do
  include_context "opening source-context bridges"

  it "registers both native opening arcs while retaining the final endpoint drift" do
    # Native SVG SHA256 abddc9443edb587d97786d7257587e5da7cf3764c62406a3eb45fb8160f0a913.
    # Its endpoint registration is source + [-150, -54]; apply the same
    # translation to every native line/arc seat, including the dy=1 endpoint.
    native_seats = [[282, 1103], [692, 1103], [704, 1103], [717, 1103], [729, 1103], [820, 1104]]
    registered = native_seats.map { |x, y| "#{x + 150} #{y + 54}" }
    expected = "M #{registered[0]} L #{registered[1]} A 6 6 180 0 0 #{registered[2]} " \
               "L #{registered[3]} A 6 6 180 0 0 #{registered[4]} L #{registered[5]}"

    expect(bridges.path_for(opening, points)).to eq(expected)
  end
end
