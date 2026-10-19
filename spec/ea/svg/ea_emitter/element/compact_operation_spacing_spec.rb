# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Element::CompartmentGeometry, "compact operation spacing" do
  include CompactOperationSpacingHelpers

  it "matches the native attribute and operation positions for an ordinary compact class" do
    g = geometry

    expect([g.attr_first_y, g.attr_bottom_y]).to eq([50, 62])
    expect([g.op_divider_y, g.op_first_y, g.op_bottom_y]).to eq([68, 82, 94])
  end

  it "tracks the last attribute row as the row count changes" do
    { 1 => [50, 56, 70, 82], 3 => [74, 80, 94, 106] }.each do |count, positions|
      g = geometry(attr_lines_count: count)

      expect([g.attr_bottom_y, g.op_divider_y, g.op_first_y, g.op_bottom_y]).to eq(positions)
    end
  end

  it "uses the actual attribute row pitch for the trailing half cell" do
    g = geometry(attr_line_offset: 8)

    expect([g.attr_first_y, g.attr_bottom_y, g.op_divider_y, g.op_first_y]).to eq([50, 64, 71, 85])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Element::CompartmentGeometry, "operation spacing preservation" do
  include CompactOperationSpacingHelpers

  it "preserves operation-only seating below the header divider" do
    g = geometry(attr_lines_count: 0)

    expect([g.divider_y, g.op_first_y, g.op_bottom_y]).to eq([37, 51, 63])
  end

  it "preserves legacy spacing outside the eligible compact standard class" do
    [
      [{ compact_standard_operations: false }, [62, 74, 83, 95]],
      [{ size_unit: "px" }, [64, 76, 85, 98]],
      [{ family: "Carlito" }, [64, 76, 85, 98]],
      [{ size: 9 }, [70, 84, 93, 108]]
    ].each do |options, positions|
      g = geometry(**options)

      expect([g.attr_bottom_y, g.op_divider_y, g.op_first_y, g.op_bottom_y]).to eq(positions)
    end
  end

  it "leaves an absent operation compartment out of the content bounds" do
    g = geometry(op_lines_count: 0)

    expect(g.op_first_y).to be_nil
    expect(g.content_bottom_y).to eq(62)
  end
end
