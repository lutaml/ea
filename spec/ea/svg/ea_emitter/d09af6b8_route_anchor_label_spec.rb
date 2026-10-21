# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
require_relative "../../../support/d09af6b8_route_anchor_helpers"

RSpec.describe "D09AF6B8 reliefComponent stored aggregation ray" do
  include D09AF6B8RouteAnchorHelpers

  let(:document) { d09_xmi_document(d09_fixture_xml) }
  let(:connector) { d09_connector(document) }
  let(:umldi) { d09_umldi_route(document, connector) }

  it "retains the mode-one stored route instead of the distinct UMLDI polyline" do
    expect(umldi).to eq([[874, 142], [781, 132], [649, 142]])
    expect(connector.style).not_to have_key(:umldi_route)
    expect(connector.waypoints.map { |waypoint| [waypoint.position.x, waypoint.position.y] })
      .to eq([[875, 155], [648, 155]])
  end

  it "clips the mathematical ray and seats the role at the native position" do
    rendered = d09_render_document(document)
    paths = rendered.xpath("//*[local-name()='path']/@d").map(&:value)

    expect(connector.connector_type).to eq("Aggregation")
    expect(paths).to include("M 532 98 L 307 98")
    expect(d09_label_position(rendered, "+reliefComponent")).to eq(["362.00", "70.00"])
    expect(d09_label_position(rendered, "1..*")).to eq(["469.00", "112.00"])
    expect(connector.source_anchor).to have_attributes(x: 1022, y: 142)
    expect(connector.target_anchor).to have_attributes(x: 562, y: 142)
  end
end

RSpec.describe "D09AF6B8 stored aggregation ray preservation" do
  include D09AF6B8RouteAnchorHelpers

  let(:document) { d09_xmi_document(d09_fixture_xml) }
  let(:umldi) { d09_umldi_route(document, d09_connector(document)) }

  it "preserves UMLDI geometry and the identified source role seat when Path is empty" do
    pathless = d09_xmi_document(d09_fixture_xml.sub("Path=781:-132$;", "Path=;"))
    connector = d09_connector(pathless)
    rendered = d09_render_document(pathless)

    expect(connector.style).to include(umldi_route: true)
    expect(connector.source_anchor).to be_nil
    expect([connector.target_anchor, connector.source_port, connector.target_port]).to eq([nil, nil, nil])
    expect(connector.waypoints.map { |waypoint| [waypoint.position.x, waypoint.position.y] }).to eq(umldi)
    expect(connector.umldi_label_bounds).to eq(source_role: { x: 704, y: 104, width: 80, height: 25 })
    expect(connector.label_boxes).to include(
      llt: include("ox" => -31, "oy" => -21, "cx" => 91, "cy" => 31),
      llb: include("ox" => -46, "oy" => -1, "cx" => 19, "cy" => 16)
    )
    expect(d09_label_position(rendered, "+reliefComponent")).to eq(["362.00", "70.00"])
  end

  it "leaves other routing modes without mathematical ray metadata" do
    other_mode = d09_xmi_document(d09_fixture_xml.sub("Mode=1;", "Mode=2;"))

    expect(d09_connector(other_mode).source_anchor).to be_nil
    expect(d09_connector(other_mode).style).not_to have_key(:association_ray_outline)
  end
end
