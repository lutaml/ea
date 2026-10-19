# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Source-backed legend item row cell baselines" do
  include LegendRowCellHelpers
  include QeaCompartmentFontHelpers

  it "uses the parsed source logical height for explicitly sized point items" do
    document = public_compartment_document
    aggregate_failures("source-backed font cohorts") do
      [
        ["0016F797-D055-4717-AF1A-606413D0A166", "4E5A37CB-F6FA-44ea-8762-5F379CFFB6A2", "90", 12, "Carlito"],
        ["6052620C-4BD5-49f6-A21C-AD7E6DCA2795", "CEA68306-BC83-4809-A89A-9B9E7D45776D", "100", 13, "Carlito"],
        ["5E2C1E2A-82A8-47f4-B2ED-1398D72BFCFD", "4E5A37CB-F6FA-44ea-8762-5F379CFFB6A2", "100", 13, "Calibri"]
      ].each do |diagram_guid, object_guid, marker, expected_offset, expected_family|
        placement, legend, svg = source_legend_row_cell(
          document: document, diagram_guid: diagram_guid, object_guid: object_guid
        )
        offsets = source_legend_row_cell_offsets(svg, placement, legend)

        expect(placement.style.fetch(:fontsz)).to eq(marker)
        expect(placement.font_logical_height).to eq(expected_offset)
        expect(offsets.length).to eq(3)
        expect(offsets.map(&:first)).to all(eq(expected_offset.to_f))
        expect(offsets.map(&:last).map { |label| label["style"] }).to all(
          include(*%W[font-size:9pt; font-family:#{expected_family};])
        )
      end
    end
  end

  it "preserves source zero and missing-size legend defaults" do
    document = public_compartment_document
    [
      %w[00C5C772-5A03-434f-BF30-AC37542A1AAC CEA68306-BC83-4809-A89A-9B9E7D45776D 0],
      ["E9CDAD85-ECF1-43de-819F-30A0D01785E6", "CEA68306-BC83-4809-A89A-9B9E7D45776D", nil]
    ].each do |diagram_guid, object_guid, marker|
      placement, legend, svg = source_legend_row_cell(
        document: document, diagram_guid: diagram_guid, object_guid: object_guid
      )
      offsets = source_legend_row_cell_offsets(svg, placement, legend)

      if marker
        expect(placement.style.fetch(:fontsz)).to eq(marker)
      else
        expect(placement.style).not_to have_key(:fontsz)
      end
      expect(placement.font_logical_height).to be_nil
      expect(offsets.length).to eq(3)
      expect(offsets.map(&:first)).to all(eq(12.0))
      expect(offsets.map(&:last).map { |label| label["style"] }).to all(
        include(*%w[font-size:7pt; font-family:Cambria;])
      )
    end
  end
end
# rubocop:enable Metrics/BlockLength

RSpec.describe "Legend item row cell preservation" do
  include LegendRowCellHelpers

  it "keeps the 12px baseline for missing and pixel logical heights" do
    [
      [9, "pt", nil],
      [9, "px", 13],
      [nil, "pt", nil]
    ].each do |size, unit, logical_height|
      legend, svg = synthetic_legend_row_cell(size: size, unit: unit, logical_height: logical_height)

      expect(legend_row_cell_offsets(svg, legend).map(&:first)).to eq([12.0])
    end
  end
end
