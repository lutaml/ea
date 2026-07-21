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

    it "unions element image bounds with margin" do
      canvas = described_class.from(diagram)
      expect(canvas.min_x).to eq(90)   # 100 - 10 margin
      expect(canvas.min_y).to eq(90)
      expect(canvas.width).to eq(520)  # (600 - 100) + 2*10
      expect(canvas.height).to eq(200) # (280 - 100) + 2*10
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
end
