# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
require_relative "../../../support/address_overlap_30d62231_helpers"

RSpec.describe "XMI address overlap source contract 30D62231" do
  include AddressOverlap30D62231Support

  it "joins the authored label rectangle to the address association end" do
    xml = Nokogiri::XML(File.read(address_fixture_path))
    property = xml.at_xpath("//*[local-name()='ownedAttribute' and @name='address']")
    connector_id = AddressOverlap30D62231Support::CONNECTOR_ID
    edge = xml.at_xpath("//*[local-name()='ownedElement' and @modelElement='#{connector_id}']")
    label = edge.at_xpath("./*[local-name()='ownedElement' and @*[local-name()='type']='umldi:UMLAssociationEndLabel']")
    box = label.at_xpath("./bounds")

    expect(property["association"]).to eq(connector_id)
    expect(label["modelElement"]).to eq(AddressOverlap30D62231Support::PROPERTY_ID)
    expect(%w[x y width height].map { |key| box[key] }).to eq(%w[1089 424 49 25])
  end
end

RSpec.describe "XMI address overlap source contract 30D62231 output" do
  include AddressOverlap30D62231Support

  it "emits the source-owned role baseline while preserving the authored route and labels" do
    document = Ea::Sources::Xmi::Adapter.from_path(address_fixture_path)
    diagram = document.diagrams.find { |entry| entry.id.include?("30D62231") }
    connector = diagram.connectors.find do |entry|
      entry.relationship_ref.end_with?(AddressOverlap30D62231Support::CONNECTOR_ID)
    end
    svg = Nokogiri::XML(Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render)
    role = svg.xpath("//*[local-name()='text']").find { |node| node.text.strip == "+address" }
    multiplicity = svg.xpath("//*[local-name()='text']").find { |node| node.text.strip == "0..*" }

    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(
      [[1171, 458], [1051, 458]]
    )
    expect([connector.source_port, connector.target_port]).to eq([nil, nil])
    expect(connector.label_boxes[:llt]).to include("ox" => 18, "oy" => -17, "cx" => 57, "cy" => 31)
    expect(svg.at_xpath("//*[local-name()='path' and @d='M 391 85 L 271 85']")).not_to be_nil
    expect([role["x"], role["y"]]).to eq(["309.00", "61.00"])
    expect([multiplicity["x"], multiplicity["y"]]).to eq(["374.00", "100.00"])
  end
end

RSpec.describe "XMI address overlap source contract 30D62231 metadata" do
  include AddressOverlap30D62231Support

  it "retains only overlap anchors without replacing authored ports or waypoints" do
    metadata = address_route_metadata

    expect(metadata.fetch(:style)).to include(umldi_route: true, overlap_ray: true)
    expect(metadata.values_at(:source_anchor, :target_anchor).map { |point| [point.x, point.y] })
      .to eq([[1232, 456], [932, 456]])
    expect(metadata).not_to have_key(:waypoints)
    expect(metadata).not_to have_key(:source_port)
    expect(metadata).not_to have_key(:target_port)
  end

  it "preserves tree, other modes, custom paths and unsupported offset geometry" do
    expect(address_route_metadata(style: { tree: "V" })).to be_empty
    expect(address_route_metadata(style: { mode: "3" })).to be_empty
    expect(address_route_metadata(style: { umldi_route: false })).to be_empty
    expect(address_route_metadata(path: "100:200;")).to be_empty
    expect(address_route_metadata(offsets: { source: [8, 12], target: [16, 11] })).to be_empty
    expect(address_route_metadata(offsets: { source: [nil, 12], target: [16, 12] })).to be_empty
    expect(address_route_metadata(edge: 0)).to be_empty
  end
end
