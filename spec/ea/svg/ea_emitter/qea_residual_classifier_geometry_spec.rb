# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA classifier content sizing" do
  include QeaCompartmentFontHelpers
  include QeaDrawnHeightHelpers

  let(:document) { public_compartment_document }

  it "fits attribute rows using their rendered font inset", :aggregate_failures do
    [
      ["508A37DC-9378-4f5a-BD96-48F4D24E03A5", "LineString", 221, 235],
      ["508A37DC-9378-4f5a-BD96-48F4D24E03A5", "LinearRing", 224, 235],
      ["360C79F1-8EDF-41db-A069-DECDC55625BC", "_CityObject", 90, 235]
    ].each do |diagram_id, name, saved_width, native_width|
      stored, drawn = qea_compartment_bounds(document, diagram_id, name)

      expect(drawn.width).to eq(native_width), name
      expect(stored.width).to eq(saved_width), name
    end
  end

  it "uses compact Cambria trailing space for overflowing attribute rows" do
    stored, drawn = qea_compartment_bounds(document, "360C79F1-8EDF-41db-A069-DECDC55625BC", "_CityObject")

    expect([stored.height, drawn.height]).to eq([70, 107])
  end
end

RSpec.describe "QEA compact enumeration sizing" do
  include QeaDrawnHeightHelpers

  let(:document) do
    path = File.expand_path("../../../../examples/qea/test.qea", __dir__)
    Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
  end

  it "uses compact Cambria trailing space for overflowing literals" do
    stored, drawn = qea_compartment_bounds(document, "B58D1A53-E860-41a3-8352-11C274093E83", "Enumeration")

    expect([stored.height, drawn.height]).to eq([70, 80])
    expect([stored.width, drawn.width]).to eq([90, 90])
  end
end
