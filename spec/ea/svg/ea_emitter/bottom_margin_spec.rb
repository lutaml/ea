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

  it "keeps the bare 10 margin below an own-package classifier nested in an owner class" do
    nested = Ea::Model::Klass.new(id: "c3", name: "Inner", package_id: "home",
                                  nested_parent_name: "Outer")

    expect(margin([placed("a", "c3", 300)], { "c3" => nested })).to eq(10)
  end

  it "keeps the bare 10 margin below an instance of the own package" do
    own = Ea::Model::InstanceSpecification.new(id: "i1", name: "Object B", package_id: "home")

    expect(margin([placed("a", "i1", 300)], { "i1" => own })).to eq(10)
  end

  it "keeps the full margin below an instance of a foreign package" do
    foreign = Ea::Model::InstanceSpecification.new(id: "i2", name: "Object B", package_id: "other")

    expect(margin([placed("a", "i2", 300)], { "i2" => foreign })).to eq(28)
  end

  context "with the basic.qea diagrams natively 10 below the lowest element" do
    let(:path) { File.expand_path("../../../../examples/qea/basic.qea", __dir__) }
    let(:document) { Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document }

    %w[3B8BD087 D14AA320 372F7F7B 4FC1D352 6D0349D5].each do |prefix|
      it "gives diagram #{prefix} the bare margin" do
        diagram = document.diagrams.find { |entry| entry.id.to_s.upcase.start_with?(prefix) }

        expect(described_class.for(diagram, document.index_by_id)).to eq(10)
      end
    end
  end

  it "keeps 13 plus the point size below a Text element of the own package" do
    text = Ea::Model::Note.new(id: "t1", note_type: "Text", package_id: "home")

    expect(margin([placed("a", "t1", 300, fontsz: "90")], { "t1" => text })).to eq(22)
  end

  it "keeps the full margin below a Text element of a foreign package" do
    text = Ea::Model::Note.new(id: "t2", note_type: "Text", package_id: "other")

    expect(margin([placed("a", "t2", 300, fontsz: "90")], { "t2" => text })).to eq(30)
  end

  describe "a Package as the lowest element" do
    def package_margin(parent_id:, show_foreign:)
      package = Ea::Model::Package.new(id: "pk", name: "Sub", parent_id: parent_id)
      diagram = Ea::Model::Diagram.new(
        id: "d", name: "D", package_id: "home", show_foreign: show_foreign,
        elements: [placed("a", "pk", 300)]
      )
      described_class.for(diagram, { "pk" => package })
    end

    it "keeps the full margin when foreign packages are shown and its parent is another package" do
      expect(package_margin(parent_id: "other", show_foreign: true)).to eq(28)
    end

    it "keeps the bare 10 margin when the diagram does not show foreign elements" do
      expect(package_margin(parent_id: "other", show_foreign: false)).to eq(10)
    end

    it "keeps the bare 10 margin for a child of the diagram's own package" do
      expect(package_margin(parent_id: "home", show_foreign: true)).to eq(10)
    end

    it "keeps the bare 10 margin for a root package" do
      expect(package_margin(parent_id: nil, show_foreign: true)).to eq(10)
    end
  end
end
