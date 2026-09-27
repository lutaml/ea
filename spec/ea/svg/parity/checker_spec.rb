# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"

RSpec.describe Ea::Svg::Parity::Checker do
  def svg_with(texts)
    body = texts.map do |(x, family, size)|
      %(<text x="#{x}" y="20" style="font-family:#{family}; font-size:#{size}">t</text>)
    end.join
    "<svg viewBox=\"0 0 100 100\">#{body}</svg>"
  end

  it "matches font families across the whole histogram, not just the first text" do
    ours = svg_with([[10, "Arial", "9"], [20, "Yu Gothic UI", "13"]])
    reference = svg_with([[10, "Yu Gothic UI", "13"], [20, "Arial", "9"]])
    report = described_class.new(ours: ours, reference: reference).report
    expect(report.font_family).to be(true)
  end

  it "fails font family when the histograms differ" do
    ours = svg_with([[10, "Arial", "9"]])
    reference = svg_with([[10, "Calibri", "9"]])
    report = described_class.new(ours: ours, reference: reference).report
    expect(report.font_family).to be(false)
  end

  it "matches equal font-size histograms" do
    ours = svg_with([[10, "Arial", "9"], [20, "Arial", "9"], [30, "Arial", "13"]])
    reference = svg_with([[10, "Arial", "13"], [20, "Arial", "9"], [30, "Arial", "9"]])
    report = described_class.new(ours: ours, reference: reference).report
    expect(report.font_size).to be(true)
  end

  it "fails when a text renders at the wrong size" do
    ours = svg_with([[10, "Arial", "9"], [20, "Arial", "9"]])
    reference = svg_with([[10, "Arial", "8"], [20, "Arial", "9"]])
    report = described_class.new(ours: ours, reference: reference).report
    expect(report.font_size).to be(false)
  end
end
