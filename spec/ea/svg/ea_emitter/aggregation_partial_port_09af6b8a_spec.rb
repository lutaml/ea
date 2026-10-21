# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
require_relative "../../../support/aggregation_partial_port_09af6b8a_helpers"

RSpec.describe "XMI partial-port aggregation ray source contract 09AF6B8A" do
  include AggregationPartialPort09AF6B8ASupport

  it "joins the UMLDI label to the composite property and native connector metadata" do
    xml = Nokogiri::XML(File.read(fixture_path))
    property = xml.at_xpath("//*[local-name()='ownedAttribute' and @name='demDmAttribute']")
    connector_id = AggregationPartialPort09AF6B8ASupport::CONNECTOR_ID
    property_id = AggregationPartialPort09AF6B8ASupport::PROPERTY_ID
    edge = xml.at_xpath("//*[local-name()='ownedElement' and @modelElement='#{connector_id}']")
    label = edge.at_xpath("./*[local-name()='ownedElement' and @*[local-name()='type']='umldi:UMLAssociationEndLabel']")
    native = xml.at_xpath("//*[local-name()='element' and @subject='#{connector_id}']")

    expect(property["aggregation"]).to eq("composite")
    expect(property["association"]).to eq(connector_id)
    expect(edge["source"]).to eq("EAID_C957C9A8_14C3_43ac_93F5_DCC06A1FB3A8")
    expect(edge["target"]).to eq("EAID_3EA549ED_B7DB_4947_939C_DD33689C7E42")
    expect(label["modelElement"]).to eq(property_id)
    expect(native["geometry"]).to include("SX=5;SY=40;EX=0;EY=0", "Path=1022:-205$1003:-205$")
    expect(native["style"]).to include("Mode=1", "LWidth=2")
  end
end

RSpec.describe "XMI partial-port aggregation ray source contract 09AF6B8A output" do
  include AggregationPartialPort09AF6B8ASupport

  it "emits the paired QEA route and role seat" do
    document = parsed_document
    diagram = fixture_diagram(document)
    connector_id = AggregationPartialPort09AF6B8ASupport::CONNECTOR_ID
    connector = diagram.connectors.find { |entry| entry.relationship_ref.end_with?(connector_id) }
    svg = render_xml(document, diagram)
    role = svg.xpath("//*[local-name()='text']").find { |node| node.text.strip == "+demDmAttribute" }

    expect(connector.connector_type).to eq("Aggregation")
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(
      [[1015, 380], [1015, 155]]
    )
    expect(svg.at_xpath("//*[local-name()='path' and @d='M 930 335 L 927 112']")).not_to be_nil
    expect([role["x"], role["y"]]).to eq(["831.00", "303.00"])
  end
end

RSpec.describe "XMI partial-port aggregation ray source contract 09AF6B8A preservation" do
  include AggregationPartialPort09AF6B8ASupport

  it "preserves unrelated UMLDI-authored routes" do
    document = parsed_document
    diagram = fixture_diagram(document)
    authored = diagram.connectors.find { |entry| entry.style[:umldi_route] }
    svg = render_xml(document, diagram)

    expect(authored.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(
      [[684, 769], [684, 673]]
    )
    expect(svg.at_xpath("//*[local-name()='path' and @d='M 601 725 L 601 629']")).not_to be_nil
  end
end

RSpec.describe "XMI partial-port aggregation ray source contract 09AF6B8A metadata gates" do
  include AggregationPartialPort09AF6B8ASupport

  it "limits partial-port metadata to its supported source shape" do
    offsets = { source: [5, 40], target: [0, 0] }
    valid = route_result(style: { mode: "1", lwidth: "2" }, offsets: offsets)

    expect(valid.keys).to include(:source_port, :source_anchor, :target_anchor, :has_geometry_offsets)
    expect(route_result(style: { mode: "1", lwidth: "2", tree: "V" }, offsets: offsets)).to be_empty
    expect(route_result(style: { mode: "3", lwidth: "2" }, offsets: offsets)).to be_empty
    expect(route_result(style: { mode: "1", lwidth: "2" }, offsets: offsets, route_flag: true)).to be_empty
    expect(route_result(style: { mode: "1", lwidth: "2" }, offsets: zero_offsets)).to be_empty
    expect(route_result(style: { mode: "1", lwidth: "2" }, offsets: { source: [5, nil], target: [0, 0] })).to be_empty
    expect(route_result(style: { mode: "1", lwidth: "2" }, offsets: both_nonzero_offsets)).to be_empty
    expect(route_result(style: { mode: "1", lwidth: "2" }, offsets: offsets, path: "")).to be_empty
  end
end
