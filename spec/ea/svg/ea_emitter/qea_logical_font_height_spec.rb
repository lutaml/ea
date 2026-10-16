# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA source font logical heights" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "retains the distinct source heights that both export as nine points" do
    records = [
      ["1A290AFD-CE96-46a2-8351-A986D77CC727", "RealEstateIDAttribute", 12],
      ["01661E1B-31B6-4167-BCCF-A00678FB4EA2", "_UrbanFunction", 13]
    ]
    records.each do |diagram_id, name, height|
      diagram = document.diagrams.find { |entry| entry.id == diagram_id }
      placement = diagram.elements.find { |entry| document.index_by_id[entry.model_element_ref]&.name == name }

      expect([placement.font_size, placement.font_size_unit, placement.font_logical_height])
        .to eq([9, "pt", height])
    end
  end
end

RSpec.describe "QEA source-height compartment metrics" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "uses the source height for both attribute pitch and advances" do
    texts = compartment_texts(document, "1A290AFD-CE96-46a2-8351-A986D77CC727")
    {
      "realEstateIDOfBuilding: xs:string" => [1333, 710, 159],
      "numberOfBuildingUnitOwnership: xs:integer [0..1]" => [1333, 724, 247],
      "realEstateIDOfBuildingUnitOwnership: xs:string [0..*]" => [1333, 738, 262],
      "realEstateIDOfLand: xs:string [0..*]" => [1333, 766, 171]
    }.each do |name, expected|
      row = texts.find { |node| node.text == name }

      # Align source diagram coordinates with the published SVG frame.
      expect([row["x"].to_f - 39, row["y"].to_f + 5, row["textLength"].to_i]).to eq(expected)
      expect(row["style"]).to include("font-family:Carlito;", "font-size:9pt;")
    end
  end
end
