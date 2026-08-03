# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/legend_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::LegendRenderer do
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 50, width: 194, height: 120) }
  let(:items) do
    [
      # BGR-packed integers as EA stores them: low byte=R, mid=G, high=B.
      # 0xCCFFCC = R=CC, G=FF, B=CC → #CCFFCC.
      Ea::Model::LegendItem.new(name: "GMLに定義されたクラス",
                                background_color: 0xCCFFCC, sort_index: 0),
      Ea::Model::LegendItem.new(name: "CityGMLに定義されたクラス",
                                background_color: 0xCCFFFF, sort_index: 1),
      Ea::Model::LegendItem.new(name: "i-URに定義されたクラス",
                                background_color: 0xFFCCFF, sort_index: 2)
    ]
  end
  let(:legend) do
    Ea::Model::Legend.new(
      title: "凡例",
      font_color: 0x603000,
      background_color: 0xF0F0F0,
      border_color: 0xD7D7D7,
      items: items
    )
  end

  describe ".render" do
    it "emits one container rect + one icon rect per item" do
      svg = described_class.render(bounds, legend: legend, family: "Carlito")
      expect(svg.scan(/<rect\b/).size).to eq(1 + items.size)
    end

    it "emits one title text + one label text per item" do
      svg = described_class.render(bounds, legend: legend, family: "Carlito")
      expect(svg.scan(/<text\b/).size).to eq(1 + items.size)
    end

    it "rounds the container corners with rx=3.00" do
      svg = described_class.render(bounds, legend: legend, family: "Carlito")
      expect(svg).to include('rx="3.00"')
    end

    it "uses the title from the legend" do
      svg = described_class.render(bounds, legend: legend, family: "Carlito")
      expect(svg).to include(">凡例<")
    end

    it "renders each item's label text" do
      svg = described_class.render(bounds, legend: legend, family: "Carlito")
      items.each do |item|
        expect(svg).to include(">#{item.name}<")
      end
    end

    it "decodes BGR background_color to #RRGGBB for the container" do
      svg = described_class.render(bounds, legend: legend, family: "Carlito")
      expect(svg).to include("fill:#F0F0F0")
    end

    it "decodes BGR font_color to #003060 for the title and labels" do
      svg = described_class.render(bounds, legend: legend, family: "Carlito")
      expect(svg).to include("fill:#003060")
    end

    it "decodes per-item BGR background_color for each icon rect" do
      svg = described_class.render(bounds, legend: legend, family: "Carlito")
      expect(svg).to include("fill:#CCFFCC")
      expect(svg).to include("fill:#FFFFCC")
      expect(svg).to include("fill:#FFCCFF")
    end
    it "renders no items layer when legend has no items" do
      empty_legend = Ea::Model::Legend.new(title: "凡例", items: [])
      svg = described_class.render(bounds, legend: empty_legend, family: "Carlito")
      expect(svg.scan(/<rect\b/).size).to eq(1)
      expect(svg.scan(/<text\b/).size).to eq(1)
    end
  end
end
