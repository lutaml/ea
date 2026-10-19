# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Public Object slot row layout" do
  include ObjectSlotLayoutHelpers

  it "uses the native compact row pitch for two-slot and three-slot owners", :aggregate_failures do
    cases = {
      "14E9F5FD-F6CD-4f48-B1CD-F5A40C6D8E83" => {
        "Object 01" => [56, [80, 92, 104]], "Object 02" => [323, [81, 93]],
        "Object 03" => [96, [239, 251, 263]], "Object 04" => [323, [242, 254, 266]],
        "Object 05" => [549, [246, 258, 270]]
      },
      "157826AA-96A7-4278-89A6-94BD0F31409A" => {
        "Object 01" => [56, [160, 172]], "Object 02" => [285, [80, 92]], "Object 03" => [285, [240, 252]]
      }
    }

    cases.each do |diagram_id, owners|
      nodes = object_slot_public_nodes(diagram_id)
      owners.each do |name, (x, baselines)|
        expect(nodes.count { |node| node.text.start_with?("#{name} /") }).to eq(1)
        rows = nodes.select do |node|
          node.text.start_with?("attribute") && node["x"].to_i == x &&
            node["y"].to_f.between?(baselines.first, baselines.last + 2)
        end
        expect(rows.map { |node| node["y"].to_f }).to eq(baselines)
        expect(rows.map { |node| node["style"] }).to all(include("font-family:Cambria;", "font-size:7pt;"))
      end
    end
  end
end

RSpec.describe "Object slot typography controls" do
  include ObjectSlotLayoutHelpers

  it "retains noncompact row spacing and supplied theme insets", :aggregate_failures do
    [["Cambria", 7, "pt", 49, [50, 62, 74]],
     ["Cambria", 7, "px", 50, [50, 63, 76]],
     ["Cambria", 9, "pt", 50, [50, 63, 76]],
     ["Carlito", 9, "pt", 50, [50, 63, 76]]].each do |family, size, unit, x, baselines|
      context = object_slot_control_context(family: family, size: size, unit: unit)
      nodes = object_slot_nodes(context)

      expect(nodes.map { |node| node["x"].to_f }).to eq([x] * 3)
      expect(nodes.map { |node| node["y"].to_f }).to eq(baselines)
    end
  end
end

RSpec.describe "Object slot subtitle centering" do
  include ObjectSlotLayoutHelpers

  it "centers foreign subtitles using their emitted widths across font units", :aggregate_failures do
    [["Cambria", 7, "pt", nil], ["Carlito", 9, "pt", 12],
     ["Carlito", 9, "px", 99]].each do |family, size, unit, height|
      context = object_slot_control_context(family: family, size: size, unit: unit, height: height)
      context.model_element.package_name = "Foreign"
      context.model_element.classifier_name = "Classifier"
      node = object_slot_nodes(context).last

      expect(node.text).to eq("(from Foreign)")
      expect(node["x"].to_f).to eq((10 + (200 - node["textLength"].to_i) / 2.0).floor)
      expect(node["style"]).to include("font-family:#{family};", "font-size:#{size}#{unit};")
    end
  end

  it "matches the eight source-owned native subtitle x positions", :aggregate_failures do
    {
      "14E9F5FD-F6CD-4f48-B1CD-F5A40C6D8E83" => [88, 128, 355, 355, 581],
      "157826AA-96A7-4278-89A6-94BD0F31409A" => [86, 315, 315]
    }.each do |diagram_id, expected_x|
      nodes = object_slot_public_nodes(diagram_id).select { |node| node.text == "(from Objects)" }

      expect(nodes.map { |node| node["x"].to_f }.sort).to eq(expected_x)
      expect(nodes.map { |node| node["textLength"].to_i }).to eq([60] * expected_x.size)
    end
  end
end
