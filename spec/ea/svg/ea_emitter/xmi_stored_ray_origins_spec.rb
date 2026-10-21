# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "C96 XMI mathematical ray origins" do
  include C96XmiRayHelpers

  let(:fixture) { File.read(fixtures_path("issue135_route_style/c96-property-ray.xmi")) }

  it "clips the saved ray and carries the role, property, and multiplicity together" do
    document = c96_xmi_document(fixture)
    connector = document.diagrams.first.connectors.first
    svg = c96_render(document)
    labels = svg.xpath("//*[local-name()='text']").to_h { |node| [node.text, [node["x"], node["y"]]] }

    expect(svg.xpath("//*[local-name()='path']/@d").map(&:value)).to include("M 120 129 L 120 379")
    expect(labels).to include(
      "+threeDimensionalExtent" => ["210.00", "147.00"],
      "«property»" => ["242.00", "159.00"],
      "0..*" => ["145.00", "152.00"]
    )
    expect(connector.source_anchor).to have_attributes(x: 321, y: 91)
    expect(connector.target_anchor).to have_attributes(x: 321, y: 422)
  end
end

RSpec.describe "C96 XMI ray preservation" do
  include C96XmiRayHelpers

  let(:fixture) { File.read(fixtures_path("issue135_route_style/c96-property-ray.xmi")) }

  it "preserves regenerated contexts and unsupported line styles" do
    variants = [fixture.sub("SuppressFOC=1", "SuppressFOC=0"), fixture.sub("Mode=1;", "Mode=2;")]

    variants.each do |xml|
      connector = c96_xmi_document(xml).diagrams.first.connectors.first
      expect(connector.source_anchor).to be_nil
      expect(connector.style).not_to have_key(:association_ray_outline)
    end
  end

  it "keeps an available UMLDI route authoritative when the authored bend is absent" do
    document = c96_xmi_document(fixture.sub("Path=321:-429$;", "Path=;"))
    connector = document.diagrams.first.connectors.first

    expect(connector.style).to include(umldi_route: true)
    expect(connector.source_anchor).to be_nil
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(
      [[321, 138], [321, 429], [321, 388]]
    )
  end
end
