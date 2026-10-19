# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Foreign instance subtitle placement" do
  include ObjectSlotLayoutHelpers

  it "matches source-owned native subtitles in both Object diagrams", :aggregate_failures do
    {
      "14E9F5FD-F6CD-4f48-B1CD-F5A40C6D8E83" =>
        [[88, 130], [128, 289], [355, 131], [355, 292], [581, 296]],
      "157826AA-96A7-4278-89A6-94BD0F31409A" =>
        [[86, 210], [315, 130], [315, 290]]
    }.each do |diagram_id, expected|
      nodes = object_slot_public_nodes(diagram_id).select { |node| node.text == "(from Objects)" }

      expect(nodes.map { |node| [node["x"].to_f, node["y"].to_f] }.sort).to eq(expected)
      expect(nodes.map { |node| node["textLength"].to_i }).to eq([60] * expected.size)
    end
  end
end

RSpec.describe "Foreign instance subtitle anchor controls" do
  include ObjectSlotLayoutHelpers

  it "anchors to the body independently of slot count and font units", :aggregate_failures do
    [["Cambria", 7, "pt"], ["Carlito", 9, "pt"], ["Carlito", 9, "px"]].each do |family, size, unit|
      [0, 1, 3].each do |count|
        context = object_slot_control_context(family: family, size: size, unit: unit)
        context.model_element.slots = context.model_element.slots.take(count)
        context.model_element.package_name = "Foreign"
        context.model_element.classifier_name = "Classifier"
        nodes = object_slot_nodes(context)

        expect(nodes.size).to eq(count + 1)
        expect(nodes.last.text).to eq("(from Foreign)")
        expect(nodes.last["y"].to_f).to eq(135)
        expect(nodes.last["style"]).to include("font-family:#{family};", "font-size:#{size}#{unit};")
      end
    end
  end
end
