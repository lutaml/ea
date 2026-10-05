# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Element::CompartmentGeometry do
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 50, width: 200, height: 150) }

  def build(header_lines: 1, attr_lines: 0, op_lines: 0, tagged_values: 0, size: 9)
    described_class.new(
      bounds: bounds, size: size,
      header_lines_count: header_lines,
      attr_lines_count: attr_lines,
      op_lines_count: op_lines,
      tagged_values_count: tagged_values
    )
  end

  describe "#header_first_y" do
    it "places the first header baseline below the element top + size + padding" do
      g = build(size: 9)
      # bounds.y (50) + size (9) + header_top_padding (12) = 71
      expect(g.header_first_y).to eq(71)
    end
  end

  describe "#divider_y" do
    it "is nil when there is no header content" do
      expect(build(header_lines: 0).divider_y).to be_nil
    end

    it "places the divider below the last header line" do
      g = build(header_lines: 2, size: 9)
      # header_first_y (71) + (2-1)*(9+6) + 8 = 94
      expect(g.divider_y).to eq(94)
    end
  end

  describe "#attr_first_y" do
    it "uses the divider position when present" do
      g = build(header_lines: 1, size: 9)
      # divider_y (71 + 0*(15) + 8 = 79) + 9 + 7 = 95
      expect(g.attr_first_y).to eq(95)
    end
  end

  describe "#attr_bottom_y" do
    it "returns the attr_first_y when no attrs are present" do
      g = build(header_lines: 1, attr_lines: 0)
      expect(g.attr_bottom_y).to eq(g.attr_first_y)
    end

    it "extends by (n-1) lines when attrs are present" do
      g = build(header_lines: 1, attr_lines: 3, size: 9)
      # attr_first_y (95) + (3-1)*(9+6) = 95 + 30 = 125
      expect(g.attr_bottom_y).to eq(125)
    end
  end

  describe "#op_first_y" do
    it "is nil when there are no operations" do
      expect(build(op_lines: 0).op_first_y).to be_nil
    end

    it "places after the attr compartment" do
      g = build(header_lines: 1, attr_lines: 1, op_lines: 2, size: 9)
      # attr_bottom_y = 95; EA's op block starts 21 below the last
      # attribute row: 95 + 9 + 14 = 118
      expect(g.op_first_y).to eq(118)
    end
  end

  describe "#tagged_value_first_y" do
    it "is nil when there are no tagged values" do
      expect(build(tagged_values: 0).tagged_value_first_y).to be_nil
    end

    it "places after the attr compartment when no ops" do
      g = build(header_lines: 1, attr_lines: 1, tagged_values: 1, size: 9)
      # base = attr_bottom_y (95), then + size + 5 = 95 + 9 + 5 = 109
      expect(g.tagged_value_first_y).to eq(109)
    end

    it "places after the op compartment when ops present" do
      g = build(header_lines: 1, attr_lines: 1, op_lines: 1, tagged_values: 1, size: 9)
      # base = op_bottom_y = 118, then + size + 5 = 132
      expect(g.tagged_value_first_y).to eq(132)
    end
  end
end