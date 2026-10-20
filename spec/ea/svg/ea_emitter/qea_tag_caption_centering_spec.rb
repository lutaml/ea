# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA tagged-value caption centering" do
  include TrailingCompartmentFontHelpers
  include TagCaptionCenteringHelpers

  it "centers the ArcGIS caption at its native x while preserving its rows" do
    nodes = arcgis_tag_caption_nodes

    expect(nodes.first["x"].to_f).to eq(156)
    expect(nodes.drop(1).map { |node| node["x"].to_f }).to all(eq(40))
    expect(nodes.map { |node| node["y"].to_f }).to eq((275..467).step(12).to_a)
  end

  it "uses native integer caption width within the simple owner bounds" do
    nodes = trailing_tag_public_nodes

    expect(nodes.first["x"].to_f).to eq(82)
    expect(nodes.map { |node| node["textLength"].to_i }).to eq([17, 80, 101])
    expect(nodes.map { |node| node["y"].to_f }).to eq([89, 101, 113])
    expect(tag_caption_nodes(width: 111).first["x"].to_f).to eq(57)
  end
end

RSpec.describe "Tagged-value caption font and inset preservation" do
  include TagCaptionCenteringHelpers

  it "uses the emitted italic family and logical height for point captions" do
    [
      ["Cambria", 7, nil, 17, 51],
      ["Carlito", 9, 12, 21, 49],
      ["Carlito", 9, 13, 23, 48]
    ].each do |family, size, height, width, x|
      node = tag_caption_nodes(family: family, size: size, logical_height: height).first

      expect([node["textLength"].to_i, node["x"].to_f]).to eq([width, x])
      expect(node["style"]).to include("font-family:#{family};", "font-style:italic;")
    end
  end

  it "retains the minimum inset and the direct pixel placement contract" do
    expect(tag_caption_nodes(width: 10).first["x"].to_f).to eq(15)
    nodes = tag_caption_nodes(family: "Carlito", size: 9, size_unit: "px", logical_height: 99)

    expect(nodes.map { |node| [node["x"].to_f, node["y"].to_f] }).to eq([[52, 50], [15, 63]])
    expect(nodes.map { |node| node["textLength"].to_i }).to eq([23, 109])
  end
end
