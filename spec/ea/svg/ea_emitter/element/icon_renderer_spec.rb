# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/icon_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::IconRenderer do
  let(:bounds) do
    Ea::Model::Bounds.new(x: 100, y: 50, width: 200, height: 80)
  end

  def parse_paths(svg)
    Nokogiri::XML("<svg>#{svg}</svg>").css("path")
  end

  def parse_first_group_style(svg)
    Nokogiri::XML("<svg>#{svg}</svg>").at_css("g")["style"]
  end

  def parse_first_path(svg)
    Nokogiri::XML("<svg>#{svg}</svg>").at_css("path")
  end

  describe ".render" do
    it "emits two paths (outer outline + folded corner)" do
      paths = parse_paths(described_class.render(bounds: bounds))
      expect(paths.size).to eq(2)
    end

    it "places the icon at top-right with the standard inset" do
      first_path = parse_first_path(described_class.render(bounds: bounds))
      d = first_path["d"]
      # Icon top-left should be at:
      #   x = bounds.right - X_INSET = 100 + 200 - 13 = 287
      #   y = bounds.top + Y_OFFSET = 50 + 3 = 53
      expect(d).to start_with("M 287 53")
    end

    it "uses square line-cap and bevel join" do
      style = parse_first_group_style(described_class.render(bounds: bounds))
      expect(style).to include("stroke-linecap:square")
      expect(style).to include("stroke-linejoin:bevel")
    end

    it "returns empty string when bounds is nil" do
      expect(described_class.render(bounds: nil)).to eq("")
    end
  end

  describe "with canvas translation" do
    let(:canvas) do
      Ea::Svg::EaEmitter::Canvas.new(min_x: 0, min_y: 0, width: 500, height: 500)
    end

    it "translates the icon position via canvas" do
      first_path = parse_first_path(described_class.render(bounds: bounds, canvas: canvas))
      # Canvas shifts by FRAME_INSET_LEFT=35, FRAME_INSET_TOP=40
      expect(first_path["d"]).to start_with("M 322 93")
    end
  end
end
