# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Legend source item fonts" do
  include LegendItemFontHelpers

  it "keeps source logical height for item widths and the title block center" do
    item, title = legend_source_texts(size: 9, logical_height: 12)

    expect(item["textLength"]).to eq("33")
    expect(title["x"]).to eq("112.00")
    expect(title["style"]).to include("font-size:12pt;", "font-weight:700;")
    expect(item["y"]).to eq("92.00")
  end

  it "uses an explicit source item size without changing the heading size" do
    item, title = legend_source_texts(size: 7, logical_height: 10)

    expect(item["style"]).to include("font-size:7pt;", "font-family:Carlito;")
    expect(title["style"]).to include("font-size:12pt;", "font-weight:700;")
  end

  it "preserves the item default when the placement has no explicit size" do
    item, title = legend_source_texts(size: nil, logical_height: nil)

    expect(item["textLength"]).to eq("36")
    expect(item["style"]).to include("font-size:9pt;", "font-family:Carlito;")
    expect(title["style"]).to include("font-size:12pt;", "font-weight:700;")
  end
end

RSpec.describe "Legend explicit item font controls" do
  include LegendItemFontHelpers

  it "preserves font families and the point-sized title with pixel-sized items" do
    %w[Arial Cambria Calibri].each do |family|
      item, title = legend_source_texts(size: 10, logical_height: nil, unit: "px", family: family)

      expect(item["style"]).to include("font-family:#{family};", "font-size:10px;")
      expect(title["style"]).to include("font-family:#{family};", "font-size:12pt;", "font-weight:700;")
    end
  end

  it "treats a zero source size as the inherited item default" do
    item, title = legend_source_texts(size: 0, logical_height: nil)

    expect(item["style"]).to include("font-size:9pt;")
    expect(item["textLength"]).to eq("36")
    expect(title["style"]).to include("font-size:12pt;")
  end
end

RSpec.describe "Legend item font metadata boundaries" do
  include LegendItemFontHelpers

  it "ignores logical height for pixel-sized items when centering the title" do
    plain_item, plain_title = legend_source_texts(size: 10, logical_height: nil, unit: "px")
    item, title = legend_source_texts(size: 10, logical_height: 12, unit: "px")

    expect(item["textLength"]).to eq(plain_item["textLength"])
    expect(title["x"]).to eq(plain_title["x"])
  end

  it "keeps the inherited default independent of context units and logical height" do
    plain_item, plain_title = legend_source_texts(size: nil, logical_height: nil)

    [[nil, "pt"], [nil, "px"], [0, "pt"], [0, "px"]].each do |size, unit|
      item, title = legend_source_texts(size: size, logical_height: 12, unit: unit)

      expect(item["style"]).to include("font-size:9pt;")
      expect(item["textLength"]).to eq(plain_item["textLength"])
      expect(title["x"]).to eq(plain_title["x"])
    end
  end
end
