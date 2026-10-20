# frozen_string_literal: true

require "spec_helper"

# Plateau diagram 99 (9400D9BC) connector 438 and diagram 62 (74C974B6)
# phantom connector 875, measured against native EA output.
RSpec.describe "Source Property roles leaving down on a centered box" do
  include LabelUpwardPropertyHelpers

  let(:anchor) { [1118, 181] }
  let(:shape) { { role: "shape", anchor: anchor } }
  let(:centered) { { "ox" => 0, "oy" => 0, "cx" => 66, "cy" => 35, "alignment" => 1 } }

  def positions(record, **options)
    upward_property_positions(record, heading: [0, 73], **options)
  end

  it "seats a persisted width-0 route at the downward Property seat" do
    result = positions(shape, box: centered, style: { mode: "3", lwidth: "0" })

    expect(result.values_at("+shape", "«property»")).to eq([[1029, 196], [1021, 208]])
  end

  it "seats a phantom outline at the downward seat with the role centered over the stereotype" do
    parent = { role: "parent", anchor: [198, 183] }
    result = positions(parent, box: { "ox" => 0, "oy" => 0 }, style: { lwidth: "1", phantom_outline: true })

    expect(result.values_at("+parent", "«property»")).to eq([[105, 198], [98, 210]])
  end

  it "keeps a width-0 route with moved offsets at its stored offsets" do
    box = centered.merge("ox" => 10, "oy" => -5)
    result = positions(shape, box: box, style: { mode: "3", lwidth: "0" })

    expect(result["+shape"]).to eq([1128, 186])
  end

  it "keeps a non-phantom absent box at its stored offsets" do
    result = positions(shape, box: { "ox" => 0, "oy" => 0 }, style: { lwidth: "1" })

    expect(result["+shape"]).to eq([1118, 181])
  end
end
