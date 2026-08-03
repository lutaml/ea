# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/hand_draw_shape_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::HandDrawShapeRenderer do
  let(:bounds) { Ea::Model::Bounds.new(x: 35, y: 40, width: 167, height: 84) }

  describe ".render" do
    it "returns a <g> wrapping a single <path>" do
      svg = described_class.render(bounds, fill: "#FFFFFF", stroke: "#000000",
                                         stroke_width: 2)
      expect(svg).to start_with(%(<g style="))
      expect(svg).to include("<path")
      expect(svg.scan(/<path\b/).size).to eq(1)
    end

    it "emits a closed shape (Z at end of path data)" do
      svg = described_class.render(bounds, fill: "#FFFFFF", stroke: "#000000",
                                         stroke_width: 2)
      path_match = svg.match(/<path d="([^"]+)"/)
      expect(path_match).not_to be_nil
      expect(path_match[1]).to end_with("Z")
    end

    it "uses the bounds corner as the path's starting point" do
      svg = described_class.render(bounds, fill: "#FFFFFF", stroke: "#000000",
                                         stroke_width: 2)
      expect(svg).to include("M 35 40")
    end

    it "includes 4 cubic bezier segments (C commands) per side" do
      svg = described_class.render(bounds, fill: "#FFFFFF", stroke: "#000000",
                                         stroke_width: 2)
      expect(svg.scan(/C /).size).to eq(4)
    end
  end
end
