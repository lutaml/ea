# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Canvas do
  describe ".from" do
    let(:diagram) do
      Ea::Model::Diagram.new(
        id: "d1",
        name: "Test",
        elements: [
          Ea::Model::DiagramElement.new(
            id: "e1",
            image_bounds: Ea::Model::Bounds.new(x: 100, y: 100, width: 200, height: 80)
          ),
          Ea::Model::DiagramElement.new(
            id: "e2",
            image_bounds: Ea::Model::Bounds.new(x: 500, y: 200, width: 100, height: 80)
          )
        ]
      )
    end

    it "unions element image bounds with frame insets" do
      canvas = described_class.from(diagram)
      expect(canvas.min_x).to eq(100)   # 100 (source min, no subtraction)
      expect(canvas.min_y).to eq(100)
      # canvas_width = element_extent + INSET_LEFT(35) + INSET_RIGHT(50) = 500 + 85 = 585
      # canvas_height = element_extent + INSET_TOP(40) + INSET_BOTTOM(57) = 180 + 97 = 277
      expect(canvas.width).to eq(585)
      expect(canvas.height).to eq(277)
    end

    it "formats width as cm" do
      canvas = described_class.from(diagram)
      expect(canvas.width_cm).to match(/\A\d+\.\d{2}cm\z/)
    end

    it "produces a 4-number viewBox string" do
      canvas = described_class.from(diagram)
      expect(canvas.view_box).to match(/\A-?\d+ -?\d+ \d+ \d+\z/)
    end
  end

  describe ".from with empty diagram" do
    it "returns a minimal canvas" do
      canvas = described_class.from(Ea::Model::Diagram.new(id: "x", name: "x"))
      expect(canvas.width).to eq(1)
      expect(canvas.height).to eq(1)
    end
  end

  describe "#translate_x / #translate_y" do
    let(:canvas) do
      described_class.new(min_x: 100, min_y: 50, width: 500, height: 300)
    end

    it "insets content x by FRAME_INSET_LEFT (35) at the min_x origin" do
      # x=min_x → translated x = inset (35)
      expect(canvas.translate_x(100)).to eq(35)
    end

    it "insets content y by FRAME_INSET_TOP (40) at the min_y origin" do
      # y=min_y → translated y = inset (40)
      expect(canvas.translate_y(50)).to eq(40)
    end

    it "preserves relative positions of off-origin points" do
      # x=200 (100 above min_x) → 200 - 100 + 35 = 135
      expect(canvas.translate_x(200)).to eq(135)
    end
  end

  describe ".coord" do
    it "renders whole numbers without decimals" do
      expect(described_class.coord(123)).to eq("123")
    end

    it "renders floats up to 2 decimals with trailing zeros stripped" do
      expect(described_class.coord(123.4)).to eq("123.4")
      expect(described_class.coord(123.456)).to eq("123.46")
    end

    it "renders 123.10 as 123.1 (trailing zero stripped)" do
      expect(described_class.coord(123.10)).to eq("123.1")
    end
  end

  describe "immutability" do
    it "exposes attributes via readers, not writers" do
      canvas = described_class.new(min_x: 0, min_y: 0, width: 10, height: 10)
      expect(canvas).to respond_to(:min_x)
      expect(canvas).not_to respond_to(:min_x=)
    end
  end
end
