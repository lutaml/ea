# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA enumeration literal insets" do
  include QeaContentHelpers

  it "matches the reference's 26-unit inset for Carlito 9pt enum rows" do
    document = Ea::Sources::Qea::Adapter.from_path("examples/qea/20251010_current_plateau_v5.1.qea")
    nodes = qea_text_nodes(document, "6797FEFA")
    literals = nodes.select { |node| %w[estimated measured].include?(node.text) }

    # The owning enum box starts at x=1131; the EA reference uses x=1157.
    expect(literals.map { |node| node["style"] }).to all(include("font-size:9pt"))
    expect(literals.map { |node| node["x"].to_f }).to eq([1157, 1157])
  end

  it "preserves explicit Calibri 7pt literal positions in the public fixture" do
    document = Ea::Sources::Qea::Adapter.from_path("examples/qea/test.qea")
    diagram = document.diagrams.find { |entry| entry.id.include?("B58D1A53") }
    # These coordinates exercise Calibri insets and row pitch, not font fallback.
    diagram.elements.each { |element| element.font_family = "Calibri" }
    nodes = qea_text_nodes(document, "B58D1A53")
    literals = nodes.select { |node| %w[val1 val2].include?(node.text) }

    expect(literals.map { |node| node["style"] }).to all(include("font-family:Calibri;", "font-size:7pt;"))
    expect(literals.map { |node| node["x"].to_f }).to eq([306, 306])
    expect(literals.map { |node| node["y"].to_f }).to eq([405, 418])
  end
end

RSpec.describe "Enumeration literal theme and unit controls" do
  include EnumInsetHelpers

  it "preserves the configured base offset at 7pt" do
    expect(enum_literal_node(size: 7, offset: 31)["x"].to_f).to eq(131)
  end

  it "adds the point-size increment to a custom theme's offset" do
    node = enum_literal_node(size: 9, offset: 31)

    expect(node["x"].to_f).to eq(135)
    expect(node["y"].to_f).to eq(60)
    expect(node.text).to eq("Blue")
  end

  it "retains the legacy fallback base when the theme omits its offset" do
    expect(enum_literal_node(size: 9, offset: nil)["x"].to_f).to eq(130)
  end

  it "preserves the existing inset for non-point font sizes" do
    expect(enum_literal_node(size: 9, offset: 31, unit: "px")["x"].to_f).to eq(131)
  end

  it "uses the compact attribute inset for 7pt Cambria literal names" do
    expect(enum_literal_node(size: 7, offset: 22, family: "Cambria")["x"].to_f).to eq(121)
  end
end

RSpec.describe "Enumeration literal compact-inset boundaries" do
  include EnumInsetHelpers

  it "preserves the configured inset outside compact Cambria point fonts" do
    [[7, "px", "Cambria", 122], [9, "pt", "Cambria", 126],
     [7, "pt", "Carlito", 122], [7, "pt", "Calibri", 122]].each do |size, unit, family, expected|
      node = enum_literal_node(size: size, offset: 22, unit: unit, family: family)

      expect(node["x"].to_f).to eq(expected)
      expect(node["y"].to_f).to eq(60)
    end
  end
end
