# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/shape_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::ShapeRenderer do
  let(:bounds) { Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 50) }

  describe ".render" do
    it "emits a <rect> at bounds position with the given size" do
      svg = described_class.render(bounds, fill: "#FFFFFF", stroke: "#000000",
                                              stroke_width: 2)
      rect = Nokogiri::XML("<svg>#{svg}</svg>").at_css("rect")
      expect(rect["x"]).to eq("10")
      expect(rect["y"]).to eq("20")
      expect(rect["width"]).to eq("100")
      expect(rect["height"]).to eq("50")
    end

    it "applies fill and stroke via the group style" do
      svg = described_class.render(bounds, fill: "#FFCC00", stroke: "#990000",
                                              stroke_width: 3)
      group = Nokogiri::XML("<svg>#{svg}</svg>").at_css("g")
      expect(group["style"]).to include("fill:#FFCC00")
      expect(group["style"]).to include("stroke:#990000")
      expect(group["style"]).to include("stroke-width:3")
    end

    it "uses rx=0.00 corner radius" do
      svg = described_class.render(bounds, fill: "#FFF", stroke: "#000",
                                              stroke_width: 2)
      rect = Nokogiri::XML("<svg>#{svg}</svg>").at_css("rect")
      expect(rect["rx"]).to eq("0.00")
    end

    it "uses shape-rendering=auto" do
      svg = described_class.render(bounds, fill: "#FFF", stroke: "#000",
                                              stroke_width: 2)
      rect = Nokogiri::XML("<svg>#{svg}</svg>").at_css("rect")
      expect(rect["shape-rendering"]).to eq("auto")
    end
  end
end
