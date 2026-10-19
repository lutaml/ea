# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA nesting SVG marker" do
  include QeaMarkerHelpers

  it "draws a white circle with a centred plus at the container (target) end" do
    markup, (start, tip) = nesting_markup("Source -> Destination")
    circle = markup.at_xpath("//ellipse")
    center = [circle["cx"].to_f, circle["cy"].to_f]

    expect(circle["rx"]).to eq("8.00")
    expect(center).to eq([tip[0] - 8, tip[1]])
    expect(start[0]).to be < tip[0]
    expect(markup.at_xpath("//path")["d"]).to eq(
      "M #{center[0].to_i} #{center[1].to_i - 8} L #{center[0].to_i} #{center[1].to_i + 8} " \
      "M #{center[0].to_i + 8} #{center[1].to_i} L #{center[0].to_i - 8} #{center[1].to_i}"
    )
  end

  it "fills the circle white so the plus draws over it" do
    markup, = nesting_markup("Source -> Destination")

    expect(markup.at_xpath("//g")["style"]).to include("fill:#FFFFFF")
    expect(markup.xpath("//g/*").map(&:name)).to eq(%w[ellipse path])
  end

  it "moves the marker to the source end when the direction is reversed" do
    markup, (start, tip) = nesting_markup("Destination -> Source")
    circle = markup.at_xpath("//ellipse")

    expect(circle["cx"].to_f).to eq(start[0] + 8)
    expect(circle["cx"].to_f).not_to eq(tip[0] - 8)
  end
end
