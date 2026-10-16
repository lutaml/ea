# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Legend item geometry" do
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 50, width: 194, height: 120) }
  let(:items) { Array.new(3) { |index| Ea::Model::LegendItem.new(name: "Row#{index}") } }

  it "keeps item geometry independent of heading size" do
    [12, 16].each do |heading_size|
      legend = Ea::Model::Legend.new(title: "Legend", heading_size: heading_size, items: items)
      svg = Ea::Svg::EaEmitter::Element::LegendRenderer.render(bounds, legend: legend, family: "Carlito")
      xml = Nokogiri::XML("<svg>#{svg}</svg>")
      icons = xml.css('rect[rx="0.00"]')
      labels = xml.css("text").reject { |node| node.text == "Legend" }
      title = xml.css("text").find { |node| node.text == "Legend" }

      expect(icons.map { |node| node["y"].to_f - bounds.y }).to eq([30, 49, 68])
      expect(labels.map { |node| node["y"].to_f - bounds.y }).to eq([42, 61, 80])
      expect(icons.map { |node| [node["width"], node["height"]] }).to eq([%w[17 17]] * 3)
      expect(title["y"].to_f - bounds.y).to eq(20)
      expect(title["style"]).to include("font-size:#{heading_size}pt;")
    end
  end
end
