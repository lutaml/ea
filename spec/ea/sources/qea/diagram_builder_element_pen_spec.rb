# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaElementPenHelpers

  it "prefers explicit placement pens over the saved object border, including black" do
    [["LCol=0;", 0xFF0000, 0], ["LCol=255;", 0, 255]].each do |placement, saved, expected|
      document = element_pen_document(placement: placement, object_color: saved)
      expect(document.diagrams.first.elements.first.line_color).to eq(expected)
    end
  end

  it "inherits saved object pens when placement colors are missing or negative" do
    [[nil, 0], ["LCol=-1;", 0xFF0000]].each do |placement, saved|
      document = element_pen_document(placement: placement, object_color: saved)
      expect(document.diagrams.first.elements.first.line_color).to eq(saved)
    end
  end

  it "leaves inherited colors unresolved when neither source supplies a pen" do
    [[nil, nil], ["LCol=-1;", -1]].each do |placement, saved|
      document = element_pen_document(placement: placement, object_color: saved)
      expect(document.diagrams.first.elements.first.line_color).to be_nil
    end
  end
end

RSpec.describe "Source element pen rendering" do
  include QeaElementPenHelpers

  it "renders the explicit black pen from the plateau Class source contract" do
    document = element_pen_document(placement: "LCol=0;LWth=2;")
    expect(rendered_element_pen(document)).to eq("#000000")
  end

  it "decodes explicit and inherited nonblack pens from BGR without changing theme fallback" do
    [["LCol=255;", 0xFF0000, "#FF0000"],
     ["LCol=-1;", 0xFF0000, "#0000FF"],
     [nil, -1, "#000000"]].each do |placement, saved, expected|
      document = element_pen_document(placement: placement, object_color: saved)
      expect(rendered_element_pen(document)).to eq(expected)
    end
  end

  it "preserves caller-supplied themes for unresolved pens and explicit colors" do
    document = element_pen_document
    document.diagrams.first.theme = document.diagrams.first.theme.with(id: "custom-pen", border_color: "#123456")
    expect(rendered_element_pen(document)).to eq("#123456")
    document.diagrams.first.elements.first.line_color = 0
    expect(rendered_element_pen(document)).to eq("#000000")
  end
end
