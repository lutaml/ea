# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Markers, "diamond pixel vertices" do
  let(:translation) { [-25, -30] }
  let(:renderer) { described_class.new(nil, model_index: nil, canvas: canvas) }
  let(:canvas) do
    double("canvas").tap do |value|
      allow(value).to receive(:translate_x) { |coordinate| coordinate + translation.fetch(0) }
      allow(value).to receive(:translate_y) { |coordinate| coordinate + translation.fetch(1) }
    end
  end

  it "rounds final coordinates for the three native Aggregation diamonds" do
    cases = [
      { tip: [986, 460], base: [985, 334], shift: [-25, -30], vertices: "956 420 961 430 966 420 961 410" },
      { tip: [927, 112], base: [930, 335], shift: [-25, -30], vertices: "907 92 902 82 897 92 902 102" },
      { tip: [739, 381], base: [738, 450], shift: [7, -30], vertices: "751 361 746 351 741 361 746 371" }
    ]

    cases.each do |marker|
      allow(canvas).to receive(:translate_x) { |coordinate| coordinate + marker.fetch(:shift).fetch(0) }
      allow(canvas).to receive(:translate_y) { |coordinate| coordinate + marker.fetch(:shift).fetch(1) }
      output = renderer.diamond_polygon(marker.fetch(:tip), marker.fetch(:base))
      actual = output.match(/points="([^"]+)"/)[1].scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a.sort
      expected = marker.fetch(:vertices).scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a.sort
      expect(actual).to eq(expected)
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Markers, "arrow pixel vertices" do
  let(:translation) { [-25, -30] }
  let(:renderer) { described_class.new(nil, model_index: nil, canvas: canvas) }
  let(:canvas) do
    double("canvas").tap do |value|
      allow(value).to receive(:translate_x) { |coordinate| coordinate + translation.fetch(0) }
      allow(value).to receive(:translate_y) { |coordinate| coordinate + translation.fetch(1) }
    end
  end

  it "rounds final coordinates for the four native source-route arrows" do
    cases = [
      { tip: [985, 334], base: [986, 460], shift: [-25, -30], vertices: "954 319 960 304 966 319" },
      { tip: [930, 335], base: [927, 112], shift: [-25, -30], vertices: "911 290 905 305 899 290" },
      { tip: [738, 450], base: [739, 381], shift: [7, -30], vertices: "751 405 745 420 739 405" },
      { tip: [514, 425], base: [511, 368], shift: [13, -30], vertices: "532 380 527 395 520 380" }
    ]

    cases.each do |marker|
      allow(canvas).to receive(:translate_x) { |coordinate| coordinate + marker.fetch(:shift).fetch(0) }
      allow(canvas).to receive(:translate_y) { |coordinate| coordinate + marker.fetch(:shift).fetch(1) }
      output = renderer.arrow_path(marker.fetch(:tip), marker.fetch(:base))
      actual = output.match(/d="([^"]+)"/)[1].scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a.sort
      expected = marker.fetch(:vertices).scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a.sort
      expect(actual).to eq(expected)
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Markers, "marker pixel geometry controls" do
  let(:renderer) { described_class.new(nil, model_index: nil) }

  it "returns nil for zero-length markers and preserves cardinal arrow geometry" do
    expect(renderer.diamond_polygon([1, 2], [1, 2])).to be_nil
    expect(renderer.arrow_path([1, 2], [1, 2])).to be_nil
    expect(renderer.arrow_path([0, 0], [0, 20])).to include("M 6 15 L 0 0 L -6 15")
    expect(renderer.arrow_path([-3, -7], [-20, -31])).to include("M -17 -16 L -3 -7 L -7 -23")
  end

  it "rounds translated final coordinates instead of rounding before translation" do
    fractional_canvas = double("fractional canvas")
    allow(fractional_canvas).to receive(:translate_x) { |coordinate| coordinate + 0.49 }
    allow(fractional_canvas).to receive(:translate_y) { |coordinate| coordinate - 0.49 }
    translated_renderer = described_class.new(nil, model_index: nil, canvas: fractional_canvas)

    expect(translated_renderer.arrow_path([0, 0], [0, 20])).to include("M 6 15 L 0 0 L -6 15")
  end
end
