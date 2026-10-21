# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
require "xmi"

RSpec.describe "C173A6F4 stored Association ray" do
  let(:source_path) { fixtures_path("association_stored_ray_c173a6f4.xmi") }
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(source_path) }
  let(:diagram) { document.diagrams.first }
  let(:connector) do
    diagram.connectors.find { |entry| entry.id.end_with?("EAID_E5DAC21D_3D66_4242_B374_6659A30A3BB4") }
  end

  it "retains the source-owned ray and endpoint labels" do
    expect(connector).not_to be_nil
    expect(connector.source_stereotype).to eq("property")
    expect(connector.label_boxes[:lrt]).to include("ox" => 3, "oy" => -26, "cx" => 93, "cy" => 18)
    expect(connector.label_boxes[:lrb]).to include("ox" => -3, "oy" => 5, "cx" => 21, "cy" => 18)
    expect(connector.style).to include(
      stored_association_ray: true,
      association_ray_outline: true,
      plain_target_seat: true
    )
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[763, 955], [461, 889]])
  end
end

RSpec.describe "C173A6F4 route and label controls" do
  let(:source_path) { fixtures_path("association_stored_ray_c173a6f4.xmi") }
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(source_path) }
  let(:diagram) { document.diagrams.first }

  it "preserves an unrelated UMLDI route and renders association labels" do
    uml_di_control = diagram.connectors.find do |entry|
      entry.id.end_with?("EAID_80974AA4_F711_4e14_AE09_A7F691605620")
    end
    expect(uml_di_control.style[:umldi_route]).to be(true)
    expect(uml_di_control.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[579, 425], [435, 425]])

    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    labels = Nokogiri::XML(svg).xpath("//*[local-name()='text']").map(&:text)
    expect(labels).to include("+lod0Geometry", "«property»", "0..1")
  end
end
