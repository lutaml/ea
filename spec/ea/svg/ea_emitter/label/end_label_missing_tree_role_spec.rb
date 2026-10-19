# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Leftward tree labels without stored role geometry" do
  include LabelUpwardPropertyHelpers

  let(:box) { { "ox" => 0, "oy" => 0, "alignment" => 1 } }
  let(:record) { { role: "member", mult: "0..*", anchor: [291, 521], box: nil } }
  let(:options) { { heading: [-30, 0], style: { mode: "3", lwidth: "2", tree: "LV" }, mult_box: box, tree: true } }

  it "keeps the tree fallback role and stereotype when the role box is absent" do
    expect(upward_property_positions(record, **options)).to eq(
      "+member" => [294, 498], "«property»" => [294, 511], "0..*" => [274, 536]
    )
  end

  it "renders basic.qea diagram 20's multiplicity-only leftward tree end" do
    positions = upward_property_positions(
      record.merge(role: nil), **options, style: { mode: "3", lwidth: "0", tree: "LV" },
                                          stereotype: nil, type: "Aggregation"
    )

    expect(positions).to eq("0..*" => [274, 536])
  end

  it "preserves the measured property seat and aligned tree fallback for stored role boxes" do
    [
      [0, { "+member" => [190, 514], "«property»" => [190, 526], "0..*" => [274, 536] }],
      [1, { "+member" => [294, 498], "«property»" => [290, 510], "0..*" => [274, 536] }]
    ].each do |alignment, expected|
      positions = upward_property_positions(record.merge(box: box.merge("alignment" => alignment)), **options)

      expect(positions).to eq(expected)
    end
  end
end
