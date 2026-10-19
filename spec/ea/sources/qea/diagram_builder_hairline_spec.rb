# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EA source outline widths" do
  include QeaBorderWidthHelpers

  it "renders source zero widths as one-pixel cosmetic outlines" do
    [["LWth=0;", -1], ["LWth=0;", 4], ["LWth=-1;", 0], [nil, 0]].each do |placement, stored|
      document = border_width_document(placement: placement, object_width: stored)
      expect(document.diagrams.first.elements.first.line_width).to eq(1)
      expect(rendered_border_width(document)).to eq(1)
    end
  end

  it "uses a one-pixel outline when source width and diagram theme are absent" do
    document = border_width_document(placement: nil)
    document.diagrams.first.style_ex = "SuppressFOC=1;"
    expect(document.diagrams.first.elements.first.line_width).to be_nil
    expect(rendered_border_width(document)).to eq(1)
  end
end

RSpec.describe "EA outline width controls" do
  include QeaBorderWidthHelpers

  it "preserves explicit positive source widths with and without a theme" do
    ["Theme=:119;SuppressFOC=1;", "SuppressFOC=1;"].each do |style|
      [["LWth=2;", 4, 2], ["LWth=-1;", 4, 4]].each do |placement, stored, expected|
        document = border_width_document(placement: placement, object_width: stored)
        document.diagrams.first.style_ex = style
        expect(rendered_border_width(document)).to eq(expected)
      end
    end
  end

  it "preserves a direct model zero width and custom inherited theme width" do
    document = border_width_document
    diagram = document.diagrams.first
    diagram.theme = diagram.theme.with(id: "outline_width_control", element_border_width: 4)
    expect(rendered_border_width(document)).to eq(4)
    diagram.elements.first.line_width = 0
    expect(rendered_border_width(document)).to eq(0)
    expect(Ea::Theme::Registry.lookup("39").stroke_width).to eq(2)
  end
end
