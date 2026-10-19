# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel, "residual source seats" do
  include LabelUpwardPropertyHelpers

  it "seats stored upward roles at their residual corners" do
    records = [
      { role: "lod1Solid", anchor: [642, 840],
        box: { "ox" => 76, "oy" => -109, "cx" => 54, "cy" => 16, "alignment" => 0 },
        style: { mode: "3", lwidth: "2", tree: "OS" }, expected: [667, 725] },
      { role: "lod2Solid", anchor: [643, 840],
        box: { "ox" => 77, "oy" => -81, "cx" => 54, "cy" => 16, "alignment" => 0 },
        style: { mode: "3", lwidth: "2", tree: "OS" }, expected: [669, 753] },
      { role: "lod3Solid", anchor: [642, 840],
        box: { "ox" => 72, "oy" => -54, "cx" => 54, "cy" => 16, "alignment" => 0 },
        style: { mode: "3", lwidth: "2", tree: "OS" }, expected: [663, 780] },
      { role: "lod4Solid", anchor: [644, 840],
        box: { "ox" => 76, "oy" => -25, "cx" => 54, "cy" => 16, "alignment" => 0 },
        style: { mode: "3", lwidth: "2", tree: "OS" }, expected: [669, 809] }
    ]

    records.each do |record|
      positions = upward_property_positions(record, stereotype: "", heading: [0, -100], style: record[:style])

      expect(positions["+#{record[:role]}"]).to eq(record[:expected])
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel, "residual OS source seat preservation" do
  include LabelUpwardPropertyHelpers

  it "keeps the stored corner outside CY16 and the measured style and font" do
    record = {
      role: "lod1Solid", anchor: [642, 840],
      box: { "ox" => 76, "oy" => -109, "cx" => 54, "cy" => 16, "alignment" => 0 },
      style: { mode: "3", lwidth: "2", tree: "OS" }
    }
    controls = [
      { box: record[:box].reject { |key, _value| key == "cy" } },
      { box: record[:box].merge("cy" => 31) },
      { style: { mode: "3", lwidth: "0", tree: "OS" } },
      { style: { mode: "1", lwidth: "2", tree: "OS" } },
      { family: "Carlito" },
      { box: record[:box].merge("rotation" => 90) }
    ]

    controls.each do |options|
      positions = upward_property_positions(
        record, stereotype: "", heading: [0, -100], style: record[:style], **options
      )

      expect(positions["+lod1Solid"]).to eq([718, 949]), options.inspect
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel, "residual source property seat" do
  include LabelUpwardPropertyHelpers

  it "seats a leftward property stereotype with its role" do
    record = {
      role: "address", anchor: [1171, 458],
      box: { "ox" => 18, "oy" => -17, "cx" => 57, "cy" => 31, "alignment" => 0 },
      style: { mode: "2", lwidth: "0", overlap_ray: true }
    }
    positions = upward_property_positions(
      record, stereotype: "property", heading: [-120, 0], style: record[:style]
    )

    expect(positions["+address"]).to eq([1089, 434])
    expect(positions["«property»"]).to eq([1089, 446])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel, "residual target seats" do
  include LabelUpwardPropertyHelpers

  it "seats leftward target network roles with their stereotypes" do
    records = [
      { role: "lod2Network", anchor: [590, 636],
        box: { "ox" => -18, "oy" => 33, "cx" => 71, "cy" => 31, "alignment" => 1 },
        tree: nil, expected: [449, 662] },
      { role: "lod3Network", anchor: [591, 608],
        box: { "ox" => 86, "oy" => -57, "cx" => 71, "cy" => 31, "alignment" => 1 },
        tree: "LH", expected: [554, 544] }
    ]

    records.each do |record|
      positions = upward_property_positions(
        record, end_kind: :target, heading: [-100, 0],
                style: { mode: "3", lwidth: "2", tree: record[:tree] },
                stereotype: "", target_stereotype: "property"
      )

      expect(positions["+#{record[:role]}"]).to eq(record[:expected])
      expect(positions["«property»"]).to eq([record[:expected][0] + 8, record[:expected][1] + 12])
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel, "residual source seat preservation" do
  include LabelUpwardPropertyHelpers

  it "preserves unsupported font and rotated leftward property seats" do
    record = {
      role: "address", anchor: [1171, 458],
      box: { "ox" => 18, "oy" => -17, "cx" => 57, "cy" => 31, "alignment" => 0 }
    }
    controls = [{ family: "Carlito" }, { size: 9 }, { box: record[:box].merge("rotation" => 90) },
                { style: { mode: "2", lwidth: "0" } }]

    controls.each do |options|
      positions = upward_property_positions(
        record, stereotype: "property", heading: [-120, 0],
                style: { mode: "2", lwidth: "0", overlap_ray: true }, **options
      )

      expect(positions["+address"]).to eq([1189, 475]), options.inspect
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel, "residual target seat preservation" do
  include LabelUpwardPropertyHelpers

  it "preserves leftward network seats outside the measured font and alignment" do
    record = {
      role: "lod2Network", anchor: [590, 636],
      box: { "ox" => -18, "oy" => 33, "cx" => 71, "cy" => 31, "alignment" => 1 }
    }
    controls = [{ family: "Carlito" }, { size: 9 }, { box: record[:box].merge("alignment" => 0) }]

    controls.each do |options|
      positions = upward_property_positions(
        record, end_kind: :target, heading: [-100, 0], style: { mode: "3", lwidth: "2" },
                stereotype: "", target_stereotype: "property", **options
      )

      expect(positions["+lod2Network"]).to eq([572, 603]), options.inspect
    end
  end
end
