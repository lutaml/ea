# frozen_string_literal: true

require "spec_helper"

RSpec.describe "D32 upward Property sources above their drawn outline" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include D32ExternalSourcePropertyHelpers

  # QEA/XMI-owned source docks and the existing reversed-corner DUID contract.
  # Expected native coordinates use the fixture's independent outline frame.
  it "seats lod1Geometry on the steep saved diagonal" do
    result = d32_external_source_labels(role: "lod1Geometry", dock_x: 41, dock_y: 75, path: "460:-320;", offset: -47)

    expect(result[:first]).to eq([436, 465])
    expect(result[:texts]).to include({ text: "+lod1Geometry", x: 309, y: 458 },
                                      { text: "«property»", x: 309, y: 470 })
  end

  it "seats lod2Geometry one pixel above the face-clipped baseline" do
    result = d32_external_source_labels(role: "lod2Geometry", dock_x: 0, dock_y: 52, path: "460:-343;", offset: -72)

    expect(result[:first]).to eq([395, 488])
    expect(result[:texts]).to include({ text: "+lod2Geometry", x: 268, y: 481 },
                                      { text: "«property»", x: 268, y: 493 })
  end

  it "preserves lod3Geometry clipped to the source face" do
    result = d32_external_source_labels(role: "lod3Geometry", dock_x: 0, dock_y: 28, path: "460:-367;", offset: -97)

    expect(result[:first]).to eq([395, 500])
    expect(result[:texts]).to include({ text: "+lod3Geometry", x: 268, y: 494 },
                                      { text: "«property»", x: 268, y: 506 })
  end
end

RSpec.describe "D32 external upward source seat scope" do
  include QeaEndLabelHelpers
  include D32ExternalSourcePropertyHelpers

  it "requires the drawn outline and the matching persisted origin" do
    outside = Ea::Model::Bounds.new(x: 600, y: 720, width: 100, height: 80)
    face = Ea::Model::Bounds.new(x: 410, y: 685, width: 100, height: 80)
    mismatch = Ea::Model::Point.new(x: 501, y: 686)
    [{ omit_bounds: true }, { bounds: nil }, { bounds: outside }, { bounds: face },
     { origin: nil }, { origin: mismatch }].each do |options|
      expect(d32_external_guard_text(**options)).to include({ text: "+lod1Geometry", x: 501, y: 685 })
    end
  end

  it "preserves adjacent routes and nondefault source presentations" do
    [{ style: { mode: "2" } }, { style: { lwidth: "2" } }, { style: { tree: "LV" } },
     { heading: [-365, -41] }, { heading: [-41, 365] }, { plain: true },
     { boxes: { llt: { "ox" => 0, "oy" => 0 } } }, { box: { "alignment" => 1 } },
     { font: "Arial" }, { size: 8 }].each do |options|
      expect(d32_external_guard_text(**options)).to include({ text: "+lod1Geometry", x: 501, y: 685 })
    end
    expect(d32_external_guard_text(box: { "ox" => 2, "oy" => 3 }))
      .to include({ text: "+lod1Geometry", x: 503, y: 682 })
  end
end

RSpec.describe "Issue 135 multiplicity of an upward Property source above its outline" do
  include QeaEndLabelHelpers
  include D32ExternalSourcePropertyHelpers

  let(:zero_box) { { "ox" => 0, "oy" => 0, "alignment" => 0 } }

  # 5038EEE3: native "0..1" sits left of and 15px below the floating anchor.
  it "right-aligns the multiplicity 3px left of the anchor, 15px below it" do
    expect(d32_external_guard_text(mult: "0..1", mult_box: zero_box))
      .to include({ text: "0..1", x: 501 - 16 - 3, y: 685 + 15 })
  end

  it "keeps the box seat when the anchor sits on the source face" do
    face = Ea::Model::Bounds.new(x: 410, y: 685, width: 100, height: 80)

    expect(d32_external_guard_text(mult: "0..1", mult_box: zero_box, bounds: face))
      .not_to include({ text: "0..1", x: 501 - 16 - 3, y: 685 + 15 })
  end
end
