# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Elements, "tag content width" do
  include BlankTagHelpers
  include TagContentWidthHelpers

  it "matches the native simple class width through the public document renderer" do
    document, diagram = native_tag_document
    element = diagram.elements.find { |entry| entry.model_element_ref == "8BB6E86F-144B-4636-8D32-171755674020" }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    nodes = Nokogiri::XML(svg).remove_namespaces!
    box = nodes.css('rect[x="35"][y="40"]').first

    expect(box["width"].to_f).to eq(111)
    expect(nodes.css("text").find { |node| node.text == "noPropertyType = false" }["textLength"]).to eq("101")
    expect(element.bounds.width).to eq(90)
  end

  [["pt", nil], ["pt", 17], ["px", 17]].each do |unit, logical_height|
    it "fits emitted #{unit} tag rows with logical height #{logical_height.inspect}" do
      width, nodes = tag_width_render({ "HighPrecision" => "false", "Short" => "0" },
                                      unit: unit, logical_height: logical_height)
      widest_row = nodes.css("text").select { |node| node.text.include?(" = ") }
                        .map { |node| node["textLength"].to_i }.max

      expect(width).to eq(widest_row + 10)
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Elements, "tag width preservation" do
  include BlankTagHelpers
  include TagContentWidthHelpers

  it "preserves boxes that already fit the tags" do
    width, = tag_width_render({ "HighPrecision" => "false" }, width: 500)
    expect(width).to eq(500)
  end

  it "ignores disabled tags when sizing the box" do
    width, nodes = tag_width_render({ "A very long tag name" => "false" }, visible: false)
    expect(width).to eq(50)
    expect(nodes.css("text").map(&:text)).not_to include("A very long tag name = false")
  end

  it "ignores missing and empty tag values when sizing the box" do
    width, = tag_width_render({ "A very long tag name" => nil, "Another very long tag name" => "" })
    expect(width).to eq(50)
  end
end
