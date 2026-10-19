# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA drawn compartment heights" do
  include QeaCompartmentFontHelpers
  include QeaDrawnHeightHelpers

  let(:document) { public_compartment_document }

  it "retains saved heights when the final attribute baseline fits", :aggregate_failures do
    [
      ["7A3649FD-E960-4ae6-B9B1-A9001C066AE7", "CityFurniture", 110],
      ["9994BF62-51E2-42cd-BB35-16C537B6718A", "PortZone", 62],
      ["9994BF62-51E2-42cd-BB35-16C537B6718A", "_UrbanFunction", 394]
    ].each do |diagram_id, name, height|
      stored, drawn = qea_compartment_bounds(document, diagram_id, name)

      expect(drawn.height).to eq(height), name
      expect(stored.height).to eq(height), name
    end
  end
end

RSpec.describe "QEA overflowing compartment heights" do
  include QeaCompartmentFontHelpers
  include QeaDrawnHeightHelpers

  let(:document) { public_compartment_document }

  it "still grows overflowing attribute and enumeration compartments", :aggregate_failures do
    [
      ["508A37DC-9378-4f5a-BD96-48F4D24E03A5", "LineString", 71, 80],
      ["508A37DC-9378-4f5a-BD96-48F4D24E03A5", "LinearRing", 70, 80],
      ["D368FDF3-BDC5-4718-A701-351C8587A376", "IfcUnitEnum", 71, 512],
      ["D368FDF3-BDC5-4718-A701-351C8587A376", "ifcInternalOrExternalEnum", 60, 107],
      ["D368FDF3-BDC5-4718-A701-351C8587A376", "IfcElementCompositionEnum", 60, 107]
    ].each do |diagram_id, name, stored_height, native_height|
      stored, drawn = qea_compartment_bounds(document, diagram_id, name)

      expect(drawn.height).to eq(native_height), name
      expect(stored.height).to eq(stored_height), name
    end
  end
end
