# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Plain leftward source role seats" do
  include LabelUpwardPropertyHelpers
  include PlainSourceSeatHelpers

  let(:record) { { role: "developmentProject", anchor: [970, 536], box: box } }
  let(:box) { { "ox" => -10, "oy" => -22, "cx" => 126, "cy" => 18, "alignment" => 1 } }
  let(:options) do
    { stereotype: nil, type: "Aggregation", heading: [-135, 0],
      style: { mode: "3", lwidth: "2", plain_source_seat: true } }
  end

  it "seats the native developmentProject right edge before its stored corner" do
    expect(upward_property_positions(record, **options)["+developmentProject"]).to eq([864, 507])
  end

  it "preserves other routes, presentations, fonts and stereotypes" do
    assert_plain_source_seat_controls(record, box, options)
  end

  it "preserves the adjacent native multiplicity" do
    positions = upward_property_positions(record.merge(mult: "0..*"), **options,
                                          mult_box: box.merge("ox" => -55, "oy" => -3, "cx" => 19))
    expect(positions["0..*"]).to eq([898, 548])
  end

  it "preserves the existing rightward and Property seats" do
    right = upward_property_positions(record, **options, heading: [135, 0])
    property = upward_property_positions(record, **options, stereotype: "property", box: box.merge("cy" => 35))

    expect(right["+developmentProject"]).to eq([963, 507])
    expect(property["+developmentProject"]).to eq([807, 507])
  end
end
