# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Package font widths and connector docking" do
  include PackageFontDockingHelpers

  it "redocks parsed direct routes against the family-aware drawn package body" do
    diagram, index = font_docking_fixture
    emitter = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: index)
    polygons = Nokogiri::XML("<svg>#{emitter.render}</svg>").css("polygon")

    expect(polygons.first["points"].split.map(&:to_f).each_slice(2).map(&:first).max).to eq(123)
    expect(emitter.drawn_bounds.fetch("s").width).to eq(123)
    expect(font_docking_path(diagram, index)).to eq("M 300 40 L 120 40 M 300 40")
    expect(font_docking_path(diagram, index, emitter.drawn_bounds)).to eq("M 300 40 L 123 40 M 300 40")
  end

  it "preserves parsed multi-segment routes outside supported redocking" do
    diagram, index = font_docking_fixture([[120, 40], [200, 40], [300, 40]])
    emitter = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: index)
    emitter.render

    expect(font_docking_path(diagram, index, emitter.drawn_bounds)).to eq("M 120 40 L 200 40 L 300 40")
  end
end
