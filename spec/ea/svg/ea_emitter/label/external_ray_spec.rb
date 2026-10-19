# frozen_string_literal: true

require "spec_helper"

RSpec.shared_context "saved external Property ray" do
  include LabelHeadingHelpers

  let(:record) do
    { points: [[856, 185], [747, 196]], anchors: [[856, 185], [747, 196]],
      box: { "ox" => 0, "oy" => 0, "alignment" => 0 } }
  end
  let(:connector) do
    build_heading_connector(record).tap do |result|
      result.connector_type = "Association"
      result.style = { mode: "1", lwidth: "2", association_ray_outline: true }
      result.label_boxes = { lrt: { "ox" => -10, "oy" => 26, "alignment" => 1 } }
    end
  end
  let(:bounds) do
    heading_bounds_for(source: [880, 150, 181, 80], target: [600, 150, 100, 100])
  end
end

RSpec.describe "Property labels on saved external rays" do
  include_context "saved external Property ray"

  it "uses the unambiguous outward source face for the complete native cluster" do
    # Plateau64:448 native [500,50], [500,62], [616,72], shifted by [221,128].
    positions = heading_positions(connector, bounds, role: "lod0MultiCurve")

    expect(positions.slice("+lod0MultiCurve", "«property»", "0..1")).to eq(
      "+lod0MultiCurve" => [721, 178], "«property»" => [721, 190], "0..1" => [837, 200]
    )
  end
end

RSpec.describe "Saved external ray label preservation" do
  include_context "saved external Property ray"

  it "preserves unflagged external anchors" do
    connector.style.delete(:association_ray_outline)
    positions = heading_positions(connector, bounds, role: "lod0MultiCurve")

    expect(positions.slice("+lod0MultiCurve", "«property»", "0..1")).to eq(
      "+lod0MultiCurve" => [856, 185], "«property»" => [856, 197], "0..1" => [868, 200]
    )
  end

  it "preserves ambiguous exterior corners" do
    connector.waypoints.last.position = heading_point([747, 100])
    connector.source_anchor = heading_point([856, 140])
    connector.target_anchor = heading_point([747, 100])
    positions = heading_positions(connector, bounds, role: "lod0MultiCurve")

    expect(positions.slice("+lod0MultiCurve", "«property»", "0..1")).to eq(
      "+lod0MultiCurve" => [856, 140], "«property»" => [856, 152], "0..1" => [868, 155]
    )
  end
end
