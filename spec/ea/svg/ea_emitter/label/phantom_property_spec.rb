# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Phantom source Property label seats" do
  include LabelUpwardPropertyHelpers

  let(:box) { { "ox" => 0, "oy" => 0 } }
  let(:style) { { phantom_outline: true } }
  let(:native_positions) { JSON.parse(File.read(fixtures_path("svg/phantom_property_positions.json"))) }

  it "matches all native phantom role, stereotype and multiplicity positions", :aggregate_failures do
    native_positions.each do |role, anchor, heading, *expected|
      positions = upward_property_positions({ role: role, anchor: anchor, box: box },
                                            style: style, heading: heading, mult_box: box)

      expect(positions).to eq(["+#{role}", "«property»", "0..1"].zip(expected).to_h)
    end
  end
end

RSpec.describe "Phantom source Property label preservation" do
  include LabelUpwardPropertyHelpers

  let(:box) { { "ox" => 0, "oy" => 0 } }
  let(:style) { { phantom_outline: true } }

  it "preserves the target Property cluster when the source also has Property labels" do
    positions = upward_property_positions({ role: "lod4Geometry", anchor: [152, 650], box: box },
                                          style: style, end_kind: :target, target_stereotype: "property",
                                          heading: [0, -1], mult_box: box)

    expect(positions).to eq("+lod4Geometry" => [152, 650], "«property»" => [152, 662], "0..1" => [160, 643])
  end

  it "preserves moved, styled, explicitly aligned and unflagged boxes" do
    [
      [{ "ox" => 9, "oy" => 2 }, style, [161, 648], [161, 660]],
      [box.merge("bold" => true), style, [152, 650], [152, 663]],
      [box.merge("alignment" => 0), style, [152, 650], [152, 662]],
      [box, {}, [152, 650], [152, 662]]
    ].each do |text_box, route, role_position, stereotype_position|
      positions = upward_property_positions({ role: "lod4Geometry", anchor: [152, 650], box: text_box },
                                            style: route, mult_box: box)

      expect(positions.fetch("+lod4Geometry")).to eq(role_position)
      expect(positions.fetch("«property»")).to eq(stereotype_position)
      expect(positions.fetch("0..1")).to eq([155, 644])
    end
  end
end
