# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::BottomMargin do
  def placed(id, ref, bottom, fontsz: nil, pixels: nil)
    bounds = Ea::Model::Bounds.new(x: 0, y: bottom - 80, width: 100, height: 80)
    Ea::Model::DiagramElement.new(id: id, model_element_ref: ref, bounds: bounds,
                                  style: fontsz ? { fontsz: fontsz } : {},
                                  font_logical_height: pixels)
  end

  def margin(elements, index)
    diagram = Ea::Model::Diagram.new(id: "d", name: "D", package_id: "home",
                                     elements: elements)
    described_class.for(diagram, index)
  end

  let(:klass) { Ea::Model::Klass.new(id: "c1", name: "Building", package_id: "p") }
  let(:note) { Ea::Model::Note.new(id: "n1", note_type: "Note") }
  let(:index) { { "c1" => klass, "n1" => note } }

  it "keeps 21 plus the point size of the lowest element's font" do
    expect(margin([placed("a", "c1", 300, fontsz: "100")], index)).to eq(31)
    expect(margin([placed("a", "c1", 300, fontsz: "90")], index)).to eq(30)
  end

  it "uses the 7 pt default when the font size is unset or zero" do
    expect(margin([placed("a", "c1", 300)], index)).to eq(28)
    expect(margin([placed("a", "c1", 300, fontsz: "0")], index)).to eq(28)
  end

  it "derives the point size from the GDI pixel height when only that is kept" do
    expect(margin([placed("a", "c1", 300, pixels: -13)], index)).to eq(31)
    expect(margin([placed("a", "c1", 300, pixels: -12)], index)).to eq(30)
  end

  it "reads only the lowest element" do
    low = placed("a", "c1", 300)
    high = placed("b", "c1", 200, fontsz: "100")

    expect(margin([high, low], index)).to eq(28)
  end

  it "keeps the bare 10 margin below a plain note" do
    expect(margin([placed("a", "n1", 300)], index)).to eq(10)
  end

  it "keeps the bare 10 margin below a classifier of the diagram's own package" do
    home = Ea::Model::Klass.new(id: "c2", name: "Road", package_id: "home")

    expect(margin([placed("a", "c2", 300)], { "c2" => home })).to eq(10)
  end

  it "keeps the owner-qualified classifier of the own package on the full margin" do
    nested = Ea::Model::Klass.new(id: "c3", name: "Inner", package_id: "home",
                                  nested_parent_name: "Outer")

    expect(margin([placed("a", "c3", 300)], { "c3" => nested })).to eq(28)
  end
end
