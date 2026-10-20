# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
require "xmi"

RSpec.describe "XMI stored Association ray" do
  let(:source_path) { fixtures_path("association_stored_ray_8dab169f.xmi") }
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(source_path) }
  let(:diagram) { document.diagrams.first }
  let(:connector) do
    diagram.connectors.find { |entry| entry.id.end_with?("EAID_E5DAC21D_3D66_4242_B374_6659A30A3BB4") }
  end

  it "uses the empty-Path Association ray and keeps unrelated UMLDI routes" do
    expect(connector).not_to be_nil
    expect(connector.style[:stored_association_ray]).to be(true)
    expect(connector.style[:association_ray_outline]).to be(true)
    expect(connector.style[:stored_top_dock]).to be(true)
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[737, 262], [739, 681]])

    preserved = diagram.connectors.find do |entry|
      entry.id.end_with?("EAID_47787155_C8F0_4572_B5C6_FD09390B1760")
    end
    expect(preserved.style[:tree]).to eq("V")
    expect(preserved.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[487, 283], [486, 236], [380, 236], [261, 56]])

    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document).render
    texts = Nokogiri::XML(svg).css("text").map(&:text)
    expect(texts).to include("+lod0Geometry", "«property»", "0..1")
  end
end
