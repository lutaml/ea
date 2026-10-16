# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Diagonal target Property seats" do
  include LabelUpwardPropertyHelpers

  let(:record) { { role: "referencePoint", anchor: [800, 640], box: box } }
  let(:box) { { "ox" => 0, "oy" => 0, "alignment" => 1 } }
  let(:options) { { end_kind: :target, target_stereotype: "property", heading: [19, -49], style: style } }
  let(:style) { { mode: "3", lwidth: "0" } }

  it "uses the leftward or upward Property right edge on diagonal legs" do
    [[[-215, 1], [670, 633]], [[19, -49], [665, 633]]].each do |heading, expected|
      positions = upward_property_positions(record, **options, heading: heading)

      expect(positions["+referencePoint"]).to eq(expected)
    end
  end

  it "preserves moved labels and unsupported presentations and directions" do
    controls = [{ box: record[:box].merge("ox" => 3, "oy" => -4), expected: [803, 644] },
                { heading: [0, -49] }, { heading: [19, 49] }, { heading: [49, -49] },
                { heading: [-19, 49] }, { heading: [49, -19] }, { family: "Carlito" },
                { end_kind: :source, target_stereotype: nil }, { target_stereotype: "Type" },
                { size: 9 }, { unit: "px" }, { box: record[:box].merge("bold" => true) },
                { box: record[:box].merge("alignment" => 0) },
                { style: { mode: "1", lwidth: "0" } }, { style: { mode: "3", lwidth: "2" } },
                { style: { mode: "3", lwidth: "0", tree: "V" } }]
    controls.each do |control|
      positions = upward_property_positions(record, **options, **control.reject { |key, _| key == :expected })

      expect(positions["+referencePoint"]).to eq(control.fetch(:expected, [800, 640])), control.inspect
    end
  end
end
