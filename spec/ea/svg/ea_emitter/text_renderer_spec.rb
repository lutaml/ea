# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::TextRenderer do
  let(:renderer) do
    described_class.new(
      content: "Hello", x: 10, y: 20,
      family: "Calibri", size: 13, weight: 700,
      style: "italic", fill: "#FF0000"
    )
  end

  it "formats x and y as decimals" do
    expect(renderer.to_svg).to include('x="10.00"')
    expect(renderer.to_svg).to include('y="20.00"')
  end

  it "includes rotation transform with same coords" do
    expect(renderer.to_svg).to include('transform="rotate(-0.00 10.00 20.00)"')
  end

  it "includes all font attributes" do
    svg = renderer.to_svg
    expect(svg).to include("font-family:Calibri")
    expect(svg).to include("font-weight:700")
    expect(svg).to include("font-style:italic")
    expect(svg).to include("font-size:13px")
  end

  it "uses provided fill for fill and default stroke for stroke" do
    svg = renderer.to_svg
    expect(svg).to include("fill:#FF0000")
    expect(svg).to include("stroke:#000000")
  end

  it "escapes XML special characters in content" do
    renderer = described_class.new(
      content: "<a> & \"b\"", x: 0, y: 0,
      family: "Calibri", size: 10
    )
    svg = renderer.to_svg
    expect(svg).to include("&lt;a&gt;")
    expect(svg).to include("&amp;")
    expect(svg).to include("&quot;")
  end

  it "computes textLength when not provided" do
    svg = renderer.to_svg
    # 5 chars * 13 * 0.65 = 42.25 → rounded to 42
    expect(svg).to include('textLength="42"')
  end

  it "uses provided textLength when given" do
    renderer = described_class.new(
      content: "X", x: 0, y: 0, family: "Calibri", size: 10,
      text_length: 100
    )
    expect(renderer.to_svg).to include('textLength="100"')
  end

  it "supports pt unit for font-size" do
    renderer = described_class.new(
      content: "X", x: 0, y: 0, family: "Carlito", size: 7,
      size_unit: "pt"
    )
    expect(renderer.to_svg).to include("font-size:7pt")
  end

  it "defaults rotation to -0.00" do
    expect(renderer.to_svg).to include("rotate(-0.00")
  end

  it "supports custom rotation" do
    renderer = described_class.new(
      content: "X", x: 5, y: 10, family: "C", size: 10,
      rotation: 45.5
    )
    expect(renderer.to_svg).to include('transform="rotate(45.50 5.00 10.00)"')
  end
end
