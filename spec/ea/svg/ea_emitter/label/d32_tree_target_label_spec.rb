# frozen_string_literal: true

require "spec_helper"

RSpec.describe "D32 plain upward LV target labels" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include LabelUpwardPropertyHelpers
  include D32TreeTargetLabelHelpers

  # The persisted LRT corner uses the existing upward plain-role seat.
  # Native (329,520) shares the fixture outline frame offset (-35,-150).
  it "seats lod4Geometry from its saved target corner" do
    result = d32_tree_target_labels

    expect(result[:last]).to eq([395, 500])
    expect(result[:texts]).to include({ text: "+lod4Geometry", x: 294, y: 370 })
    expect(result[:mult]).to eq([343, 531])
  end

  it "preserves adjacent styles, headings and nonplain presentations" do
    [{ style: { mode: "2", lwidth: "0", tree: "LV" } },
     { style: { mode: "3", lwidth: "1", tree: "LV" } },
     { style: { mode: "3", lwidth: "0", tree: "V" } },
     { style: { mode: "3", lwidth: "0", tree: "LH" } },
     { heading: [1, -325] }, { heading: [0, 325] },
     { end_kind: :source, heading: [0, 325] }, { target_stereotype: "Type" }, { family: "Carlito" },
     { box: { "ox" => -26, "oy" => -123, "alignment" => 2 } }].each do |options|
      positions = d32_tree_target_positions(**options)

      expect(positions["+lod4Geometry"]).to eq([434, 843])
    end
  end

  it "keeps missing target role boxes absent" do
    expect(d32_tree_target_positions(box: nil)).not_to have_key("+lod4Geometry")
  end
end
