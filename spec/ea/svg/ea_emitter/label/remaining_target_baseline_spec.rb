# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Basic ALN2 horizontal target role baseline" do
  include RemainingTargetBaselineHelpers
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  it "uses the saved corner baseline in both independently joined directions and seats x by the native ALN2 offsets" do
    left = remaining_target_baseline
    right = remaining_target_baseline(heading: [148, 0], anchor: [235, 130],
                                      box: { "ox" => 5, "oy" => 1, "cx" => 41, "cy" => 13 })

    expect(left.fetch("+role b")).to eq([362.0, 128.0])
    expect(right.fetch("+role b")).to eq([244.0, 124.0])
    expect(left.fetch("0..1")).to eq([380.0, 152.0])
  end

  it "applies the baseline through the public QEA adapter and labels layer" do
    expect(remaining_target_baseline_qea.fetch("+role b")).to eq([497.0, 128.0])
  end

  it "uses only the target stereotype to select the plain target baseline" do
    expect(remaining_target_baseline(source_stereotype: "property").fetch("+role b")).to eq([362.0, 128.0])
  end

  it "keeps the baseline independent of the saved horizontal extent" do
    expect(remaining_target_baseline(box: { "cx" => 90 }).fetch("+role b")).to eq([362.0, 128.0])
  end
end

RSpec.describe "Basic ALN2 target baseline preservation" do
  include RemainingTargetBaselineHelpers

  it "preserves legacy positions outside the saved horizontal plain target regime" do
    [{ heading: [-182, 1] }, { heading: [0, -182] }, { heading: [0, 0] },
     { style: { mode: "2" } }, { style: { lwidth: "2" } }, { style: { tree: "H" } },
     { style: { stored_association_ray: false } }, { font: { family: "Arial" } },
     { font: { weight: 700 } }, { font: { style: "italic" } },
     { font: { size: 8 } }, { font: { unit: "px" } }, { box: { "alignment" => 0 } },
     { box: { "alignment" => 1 } }, { box: { "cy" => 16 } }, { box: { "bold" => true } },
     { box: { "italic" => true } }, { box: { "underline" => true } },
     { box: { "hidden" => true } }, { box: { "color" => 123 } },
     { box: { "direction" => 1 } }, { box: { "rotation" => 90 } }, { stereotype: "property" }, { type: "Aggregation" },
     { end_kind: :source }].each do |options|
      expect(remaining_target_baseline(**options).fetch("+role b")).to eq([394.0, 139.0]), options.inspect
    end
  end
end
