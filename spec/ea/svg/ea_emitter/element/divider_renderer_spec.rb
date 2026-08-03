# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/divider_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::DividerRenderer do
  let(:bounds) { Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 50) }

  describe ".render" do
    it "emits a horizontal <path> from bounds.x to bounds.x + width" do
      svg = described_class.render(bounds, y: 30, stroke: "#000000", stroke_width: 2)
      path = Nokogiri::XML("<svg>#{svg}</svg>").at_css("path")
      expect(path["d"]).to eq("M 10 30 L 110 30")
    end

    it "uses the stroke and stroke-width in the group style" do
      svg = described_class.render(bounds, y: 30, stroke: "#FF0000", stroke_width: 3)
      group = Nokogiri::XML("<svg>#{svg}</svg>").at_css("g")
      expect(group["style"]).to include("stroke:#FF0000")
      expect(group["style"]).to include("stroke-width:3")
    end

    it "uses bevel line-join and round line-cap" do
      svg = described_class.render(bounds, y: 30, stroke: "#000000", stroke_width: 2)
      group = Nokogiri::XML("<svg>#{svg}</svg>").at_css("g")
      expect(group["style"]).to include("stroke-linecap:round")
      expect(group["style"]).to include("stroke-linejoin:bevel")
    end

    it "has zero fill opacity (pure stroke)" do
      svg = described_class.render(bounds, y: 30, stroke: "#000000", stroke_width: 2)
      group = Nokogiri::XML("<svg>#{svg}</svg>").at_css("g")
      expect(group["style"]).to include("fill-opacity:0.00")
    end
  end
end
