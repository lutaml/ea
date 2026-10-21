# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Legend title extents" do
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 50, width: 300, height: 120) }
  let(:legend) do
    Ea::Model::Legend.new(
      title: "Legend heading",
      items: [Ea::Model::LegendItem.new(name: "Classification")]
    )
  end

  it "centers a bold title using its emitted extent and preserves regular item metrics" do
    %w[Carlito Calibri].each do |family|
      svg = Ea::Svg::EaEmitter::Element::LegendRenderer.render(bounds, legend: legend, family: family)
      texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
      item, title = texts
      block_left = bounds.x + 10
      block_right = item["x"].to_f + item["textLength"].to_i
      centered_x = ((block_left + block_right - title["textLength"].to_i) / 2).floor

      expect(title["x"].to_f).to eq(centered_x)
      expect(title["style"]).to include("font-weight:700", "font-size:12pt")
      expect(item["style"]).to include("font-weight:0", "font-size:9pt")
      expect(item["textLength"].to_i).to eq(69)
      expect([item["x"], item["y"]]).to eq(["132.00", "92.00"])
    end
  end
end

RSpec.describe "Legend CJK fallback extents" do
  it "centers the Cambria CJK fallback using emitted extents and preserves items" do
    bounds = Ea::Model::Bounds.new(x: 100, y: 50, width: 300, height: 120)
    legend = Ea::Model::Legend.new(title: "凡例", items: [Ea::Model::LegendItem.new(name: "GMLに定義されたクラス")])
    svg = Ea::Svg::EaEmitter::Element::LegendRenderer.render(bounds, legend: legend, family: "Cambria")
    item, title = Nokogiri::XML("<svg>#{svg}</svg>").css("text")

    centered_x = ((bounds.x + 10 + item["x"].to_f + item["textLength"].to_i - title["textLength"].to_i) / 2).floor
    expect(title["x"].to_f).to eq(centered_x)
    expect([title["x"], title["y"], title["textLength"]]).to eq(["141.00", "70.00", "34"])
    expect([item["x"], item["y"], item["textLength"]]).to eq(["132.00", "92.00", "74"])
  end
end

RSpec.describe "Legend fallback title centering" do
  it "uses emitted extents for unsupported families and preserves item geometry" do
    bounds = Ea::Model::Bounds.new(x: 100, y: 50, width: 300, height: 120)
    ["凡例", "Wide heading"].each do |heading|
      legend = Ea::Model::Legend.new(title: heading, items: [Ea::Model::LegendItem.new(name: "Classification")])
      svg = Ea::Svg::EaEmitter::Element::LegendRenderer.render(bounds, legend: legend, family: "Unavailable Font")
      item, title = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
      block_right = item["x"].to_f + item["textLength"].to_i
      centered_x = ((bounds.x + 10 + block_right - title["textLength"].to_i) / 2).floor

      expect(title["x"].to_f).to eq(centered_x)
      expect([item["x"], item["y"], item["textLength"]]).to eq(["132.00", "92.00", "66"])
      expect(title["style"]).to include("font-family:Unavailable Font", "font-weight:700", "font-size:12pt")
    end
  end
end

RSpec.describe "Legend fractional metric extents" do
  it "centers integer emitted widths while preserving fractional metric item output" do
    bounds = Ea::Model::Bounds.new(x: 100, y: 50, width: 300, height: 120)
    %w[Carlito Calibri].each do |family|
      [["A日", "14", "72.00"], ["A日日", "21", "76.00"]].each do |label, width, title_x|
        legend = Ea::Model::Legend.new(title: "Legend heading", items: [Ea::Model::LegendItem.new(name: label)])
        svg = Ea::Svg::EaEmitter::Element::LegendRenderer.render(bounds, legend: legend, family: family)
        item, title = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
        centered_x = ((bounds.x + 10 + item["x"].to_f + width.to_i - title["textLength"].to_i) / 2).floor

        expect(title["x"].to_f).to eq(centered_x)
        expect([title["x"], title["y"], title["textLength"]]).to eq([title_x, "70.00", "111"])
        expect([item["x"], item["y"], item["textLength"]]).to eq(["132.00", "92.00", width])
      end
    end
  end
end
