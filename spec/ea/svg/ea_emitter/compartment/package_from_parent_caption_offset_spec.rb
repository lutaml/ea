# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Compartment::PackageFromParent do
  def caption_y(family, size, logical_height: nil)
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 400, y: 20, width: 100, height: 80),
      family: family, size: size, size_unit: "pt", logical_height: logical_height,
      theme: Ea::Theme::Registry.default
    )
    svg = described_class.subtitle("(from 3D都市モデル)", context)
    Nokogiri::XML("<svg>#{svg}</svg>").at_css("text")["y"].to_f
  end

  it "places a Carlito 9pt caption 17px below the body (native 37AC19B9: 100 -> 117)" do
    expect(caption_y("Carlito", 9)).to eq(117.0)
  end

  it "keeps the 15px offset for Cambria 7pt captions (native 14E9F5FD, 2A5E0832, 6481E2CC)" do
    expect(caption_y("Cambria", 7)).to eq(115.0)
  end

  it "treats a zero logical height as absent (same offset as no height)" do
    expect(caption_y("Cambria", 9, logical_height: 0)).to eq(caption_y("Cambria", 9))
  end

  it "keeps the legacy 15px offset for an absurd logical height instead of moving the caption away" do
    expect(caption_y("Cambria", 9, logical_height: 500)).to eq(115.0)
  end
end
