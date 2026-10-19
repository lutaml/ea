# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Default attribute content seats" do
  include DefaultAttributeSeatHelpers
  include QeaContentHelpers
  include QeaCompartmentFontHelpers

  it "matches native default 7pt and explicit 9pt rows in Plateau diagram164" do
    nodes = qea_text_nodes(public_compartment_document, "38170608")
    rows = nodes.select do |node|
      ["rank: gml:CodeType [0..1]", "class: gml:CodeType [0..1]"].include?(node.text)
    end

    # Native box-relative seats are 21 for Cambria 7pt and 26 for Carlito 9pt.
    expect(rows.map { |node| [node.text, node["x"].to_f, node["y"].to_f] })
      .to contain_exactly(["class: gml:CodeType [0..1]", 346, 97],
                          ["rank: gml:CodeType [0..1]", 330, 315])
  end

  it "matches the native default attribute seat in test diagram4" do
    document = Ea::Sources::Qea::Adapter.from_path("examples/qea/test.qea")
    row = qea_text_nodes(document, "B58D1A53").find { |node| node.text == "character: Character" }

    expect([row["x"].to_f, row["y"].to_f]).to eq([56, 101])
  end
end

RSpec.describe "Inherited attribute content seats" do
  include DefaultAttributeSeatHelpers

  it "uses the inherited content seat while preserving the visibility seat" do
    [Ea::Theme::Registry.default, Ea::Theme::Registry.lookup("39")].each do |theme|
      nodes = attribute_seat_nodes(theme, family: "Cambria")

      expect(nodes.map { |node| node["x"].to_f }).to eq([105, 121])
      expect(nodes.map { |node| node["y"].to_f }).to eq([60, 60])
    end
  end

  it "grows narrow default and Theme39 boxes to contain the resolved seat" do
    [Ea::Theme::Registry.default, Ea::Theme::Registry.lookup("39")].each do |theme|
      stored, drawn, row = inherited_attribute_sizing_render(theme)

      expect(drawn.width).to eq(row["x"].to_f - drawn.x + row["textLength"].to_i + 5)
      expect(stored.width).to eq(40)
    end
  end
end

RSpec.describe "Explicit attribute content seats" do
  include DefaultAttributeSeatHelpers

  it "honors explicit theme offsets and the renderer's nil fallback" do
    { 20 => 120, 40 => 140, 22 => 122, nil => 122 }.each do |offset, expected|
      spec = Ea::Theme::Definition::AttrSpec.new(visibility_x_offset: 5, content_x_offset: offset)
      theme = Ea::Theme::Registry.default.with(attribute_spec: spec)

      expect(attribute_seat_nodes(theme).map { |node| node["x"].to_f }).to eq([105, expected])
    end
    expect(attribute_seat_nodes(Ea::Theme::Registry.lookup("119"), size: 9).last["x"].to_f).to eq(126)
  end
end
