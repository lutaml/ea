# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Background do
  let(:canvas) do
    Ea::Svg::EaEmitter::Canvas.new(min_x: 0, min_y: 0, width: 500, height: 300)
  end

  describe ".render" do
    it "emits a <g> wrapping a white-filled rect" do
      svg = described_class.render(canvas)
      expect(svg).to include("<g style=\"fill:#FFFFFF;fill-opacity:1.00;\">")
      expect(svg).to include("<rect")
    end

    it "sizes the rect to the canvas dimensions" do
      svg = described_class.render(canvas)
      expect(svg).to include('width="500"')
      expect(svg).to include('height="300"')
    end

    it "anchors the rect at (0, 0)" do
      svg = described_class.render(canvas)
      expect(svg).to include('x="0"')
      expect(svg).to include('y="0"')
    end
  end
end
