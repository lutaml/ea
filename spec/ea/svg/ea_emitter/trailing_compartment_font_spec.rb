# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Trailing compartment font context" do
  include TrailingCompartmentFontHelpers

  it "retains the native point unit on simple.qea diagram2 tagged values" do
    nodes = trailing_tag_public_nodes

    expect(nodes.map(&:text)).to eq(["tags", "noPropertyType = false", "isCollection = false"])
    expect(nodes.map { |node| node["style"] }).to all(include("font-family:Cambria;", "font-size:7pt;"))
    expect(nodes.map { |node| node["textLength"].to_i }).to eq([17, 101, 80])
  end

  it "retains the source logical height in tag rows and their italic caption" do
    nodes = trailing_tag_nodes(size_unit: "pt", logical_height: 12)

    expect(nodes.map { |node| node["textLength"].to_i }).to eq([21, 102])
    expect(nodes.map { |node| node["style"] }).to all(include("font-size:9pt;"))
  end

  it "retains the source logical height in instance slots and the foreign subtitle" do
    nodes = trailing_slot_nodes(size_unit: "pt", logical_height: 12)

    expect(nodes.map { |node| node["textLength"].to_i }).to eq([102, 71])
  end

  it "uses pixel metrics independently of source logical height and preserves positions" do
    tags = trailing_tag_nodes(size_unit: "px", logical_height: 12)
    slots = trailing_slot_nodes(size_unit: "px", logical_height: 12)

    expect(tags.map { |node| [node["x"].to_f, node["y"].to_f] }).to eq([[52, 50], [15, 63]])
    expect(slots.map { |node| [node["x"].to_f, node["y"].to_f] }).to eq([[32, 50], [72, 235]])
    # Carlito's c advance (0.4229em) quantizes to 6px at H13,
    # making HighPrecision = false 109px with subpixel rounding.
    expect(tags.map { |node| node["textLength"].to_i }).to eq([23, 109])
    expect(slots.map { |node| node["textLength"].to_i }).to eq([109, 76])
    expect((tags + slots).map { |node| node["style"] }).to all(include("font-size:9px;"))
  end
end

RSpec.describe "Trailing compartment pixel font context" do
  include TrailingCompartmentFontHelpers

  it "ignores source logical height for pixel widths" do
    expect(trailing_tag_nodes(size_unit: "px", logical_height: 99).map { |node| node["textLength"].to_i })
      .to eq([23, 109])
    expect(trailing_slot_nodes(size_unit: "px", logical_height: 99).map { |node| node["textLength"].to_i })
      .to eq([109, 76])
  end
end
