# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Ordinary QEA note silhouettes" do
  include NoteShapeHelpers

  it "renders all six body-bearing placements with a folded corner and no duplicate body text" do
    placements = %w[20251010_current_plateau_v5.1 ArcGISWorkspace_template].flat_map do |name|
      qea_note_shapes(Ea::Sources::Qea::Adapter.from_path("examples/qea/#{name}.qea"))
    end

    expect(placements.size).to eq(6)
    placements.each do |model, bounds|
      svg = Ea::Svg::EaEmitter::Compartment::Shape.render(note_shape_context(model, bounds))
      nodes = Nokogiri::XML("<svg>#{svg}</svg>")
      x = bounds.x
      y = bounds.y
      right = x + bounds.width
      bottom = y + bounds.height

      expect(nodes.css("polygon, text")).to be_empty
      outer = "M #{x} #{y} L #{right - 12} #{y} L #{right} #{y + 12} " \
              "L #{right} #{bottom} L #{x} #{bottom} L #{x} #{y} Z"
      fold = "M #{right - 12} #{y} L #{right - 12} #{y + 12} L #{right} #{y + 12}"
      expect(nodes.css("path").map { |path| path["d"] }).to eq([outer, fold])
    end
  end
end

RSpec.describe "Note shape dispatch controls" do
  include NoteShapeHelpers

  let(:bounds) { Ea::Model::Bounds.new(x: 30, y: 40, width: 200, height: 100) }

  it "preserves package labels and stereotypes" do
    model = Ea::Model::Package.new(id: "P", name: "Schema", stereotype_refs: ["applicationSchema"])
    svg = Ea::Svg::EaEmitter::Compartment::Shape.render(note_shape_context(model, bounds))
    nodes = Nokogiri::XML("<svg>#{svg}</svg>")

    expect(nodes.css("polygon").size).to eq(2)
    expect(nodes.css("text").map(&:text)).to eq(["«applicationSchema»", "Schema"])
  end

  it "preserves the ordinary classifier rectangle" do
    model = Ea::Model::Classifier.new(id: "C", name: "Feature")
    svg = Ea::Svg::EaEmitter::Compartment::Shape.render(note_shape_context(model, bounds))

    expect(Nokogiri::XML("<svg>#{svg}</svg>").css("rect").size).to eq(1)
  end

  it "keeps legend notes on their legend renderer path" do
    legend = Ea::Model::Legend.new(title: "Legend", items: [Ea::Model::LegendItem.new(name: "Class")])
    model = Ea::Model::Note.new(id: "L", body: "Ignored body", legend: legend)
    svg = Ea::Svg::EaEmitter::Compartment::Shape.render(note_shape_context(model, bounds))
    expected = Ea::Svg::EaEmitter::Element::LegendRenderer.render(bounds, legend: legend, family: "Carlito")

    expect(svg).to eq(expected)
  end
end
