# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Plain leftward target role seats" do
  include LabelUpwardPropertyHelpers
  include PlainTargetSeatHelpers

  let(:box) { { "ox" => 0, "oy" => 0, "cx" => 113, "cy" => 18, "alignment" => 1 } }
  let(:record) { { role: "lod-1MultiSurface", anchor: [431, 116], box: box } }
  let(:style) { { mode: "3", lwidth: "2", plain_target_seat: true } }
  let(:options) { plain_target_seat_options(style) }

  it "seats both native roles three pixels before the target anchor" do
    [[[431, 116], [344, 109]], [[451, 77], [364, 70]]].each do |anchor, expected|
      positions = upward_property_positions(record.merge(anchor: anchor), **options)

      expect(positions["+lod-1MultiSurface"]).to eq(expected)
    end
  end

  it "preserves other routes, presentations, fonts and stereotypes" do
    plain_target_seat_controls(box, style).each do |control|
      positions = upward_property_positions(record, **options, **control)

      expect(positions["+lod-1MultiSurface"]).to eq([431, 116]), control.inspect
    end
  end

  it "preserves moved boxes and existing rightward and Property seats" do
    moved = upward_property_positions(record, **options, box: box.merge("ox" => 10, "oy" => -4))
    right = upward_property_positions(record, **options, heading: [133, 0])
    property = upward_property_positions(record, **options, target_stereotype: "property")

    expect([moved["+lod-1MultiSurface"], right["+lod-1MultiSurface"]]).to eq([[441, 120], [434, 109]])
    expect(property).to eq({ "+lod-1MultiSurface" => [431, 116], "«property»" => [449, 128], "0..1" => [431, 116] })
  end
end
