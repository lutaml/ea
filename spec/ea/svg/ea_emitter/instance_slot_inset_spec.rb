# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Instance slot content inset" do
  include InstanceSlotInsetHelpers

  it "matches basic.qea diagram7 RunState rows without moving their headers", :aggregate_failures do
    texts = basic_runstate_texts.to_h { |node| [node.text, node] }
    expected = {
      "Variable A = Value One" => [56, 80, 99],
      "Variable B = Value One" => [293, 81, 99],
      "Object A" => [82, 59, 39],
      "Object B" => [319, 60, 39]
    }

    expected.each do |content, coordinates|
      node = texts.fetch(content)
      expect([node["x"].to_f, node["y"].to_f, node["textLength"].to_i]).to eq(coordinates)
      expect(node["style"]).to include("font-family:Cambria;", "font-size:7pt;")
    end
  end
end

RSpec.describe "Instance slot font and theme controls" do
  include InstanceSlotInsetHelpers

  it "adjusts only compact point fonts relative to the supplied theme inset", :aggregate_failures do
    [
      ["Cambria", 7, "pt", 22, 31],
      ["Cambria", 7, "pt", 40, 49],
      ["Cambria", 7, "pt", nil, 35],
      ["Cambria", 7, "px", 22, 32],
      ["Cambria", 9, "pt", 22, 32],
      ["Carlito", 7, "pt", 22, 32],
      ["Arial", 7, "pt", 40, 50]
    ].each do |family, size, unit, inset, x|
      node = instance_slot_inset_node(family: family, size: size, unit: unit, inset: inset)

      expect([node["x"].to_f, node["y"].to_f]).to eq([x, 50])
      expect(node.text).to eq("Variable A = Value One")
      expect(node["style"]).to include("font-family:#{family};", "font-size:#{size}#{unit};")
    end
  end
end
