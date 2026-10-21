# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA source-height baseline anchors" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "aligns twelve-pixel headers and first and later attribute rows with the published SVG" do
    records = [
      ["1A290AFD-CE96-46a2-8351-A986D77CC727", [-25, -35],
       { "uro::RealEstateIDAttribute" => [1396, 687],
         "realEstateIDOfBuilding: xs:string" => [1333, 710],
         "numberOfBuildingUnitOwnership: xs:integer [0..1]" => [1333, 724] }],
      ["2A339928-E5EF-4ed2-9E5D-CC2CA5CF248B", [-25, -30],
       { "_Site" => [412, 24], "bldg::_AbstractBuilding" => [199, 58],
         "class: gml:CodeType [0..1]" => [100, 81] }]
    ]
    records.each do |id, shift, expected|
      diagram = document.diagrams.find { |entry| entry.id == id }
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                      document: document, frame: true).render
      texts = Nokogiri::XML(svg).remove_namespaces!.css("text")
      expected.each do |text, position|
        rows = texts.select { |node| node.text == text }

        expect(rows.length).to eq(1)
        expect([rows.first["x"].to_f + shift[0], rows.first["y"].to_f + shift[1]])
          .to eq(position)
      end
    end
  end
end

RSpec.describe "Compartment baseline preservation" do
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 50, width: 200, height: 150) }

  it "preserves nominal source heights, other font families, and pixel fonts" do
    records = [
      ["Carlito", 9, "pt", 13, 71, 95],
      ["Carlito", 7, "pt", 10, 69, 91],
      ["Cambria", 7, "pt", 10, 69, 90],
      ["Carlito", 9, "px", 12, 71, 95],
      ["Carlito", 9, "pt", nil, 71, 95]
    ]
    records.each do |family, size, unit, height, *positions|
      geometry = Ea::Svg::EaEmitter::Element::CompartmentGeometry.new(
        bounds: bounds, size: size, family: family, size_unit: unit, logical_height: height,
        header_lines_count: 1, attr_lines_count: 2, op_lines_count: 0, tagged_values_count: 0
      )

      expect([geometry.header_first_y, geometry.attr_first_y]).to eq(positions)
    end
  end
end
