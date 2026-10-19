# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Enumeration content width" do
  include EnumContentWidthHelpers

  it "fits the IfcUnitEnum literal with five units of right padding" do
    renderer, nodes = enum_width_render
    literal = nodes.find { |node| node.text == "THERMODYNAMICTEMPERATUREUNIT" }

    expect(literal["textLength"].to_i).to eq(201)
    expect(literal["x"].to_f).to eq(126)
    expect(renderer.drawn_bounds.fetch("enum").width).to eq(232)
    expect(renderer.diagram.elements.first.bounds.width).to eq(190)
  end
end

RSpec.describe "Enumeration width rendering controls" do
  include EnumContentWidthHelpers

  it "uses the actual displayed code, inset, font units and logical height" do
    [[9, "pt", "Carlito", 31, 15], [7, "pt", "Cambria", 22, nil],
     [9, "px", "Carlito", 31, 20], [7, "pt", "Unknown font", nil, nil]].each do |size, unit, family, offset, height|
      renderer, nodes = enum_width_render(width: 40, literal_name: "Blue", value: "LONG_CODE_VALUE",
                                          size: size, unit: unit, family: family,
                                          offset: offset, logical_height: height, marker: true)
      literal = nodes.find { |node| node.text == "Blue = LONG_CODE_VALUE" }
      expected = literal["x"].to_f - 100 + literal["textLength"].to_i + 5

      expect(renderer.drawn_bounds.fetch("enum").width).to eq(expected)
      expect(nodes.map(&:text)).to include("{root}")
    end
  end

  it "preserves short literals, larger source widths and empty compartments" do
    [{ literal_name: "Blue", width: 220 }, { width: 300 }, { literals: false }].each do |options|
      renderer, = enum_width_render(**options)

      expect(renderer.drawn_bounds.fetch("enum").width).to eq(options.fetch(:width, 190))
    end
  end

  it "does not size filtered enum placements or emit their literal rows" do
    renderer, nodes = enum_width_render(name: "", background: -1)

    expect(nodes).to be_empty
    expect(renderer.drawn_bounds).to be_empty
    expect(renderer.diagram.elements.first.bounds.width).to eq(190)
  end
end
