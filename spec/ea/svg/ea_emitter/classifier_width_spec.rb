# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Document do
  let(:klass) do
    Ea::Model::Klass.new(
      id: "c1",
      name: "Building",
      package_id: "p1",
      stereotype_refs: ["FeatureType"],
      properties: [
        Ea::Model::Property.new(id: "p1", name: "height", type_name: "Integer",
                                 owner_id: "c1")
      ],
      operations: [
        Ea::Model::Operation.new(
          id: "o1", name: "register", owner_id: "c1",
          return_type_name: "Building",
          parameters: [
            Ea::Model::Parameter.new(id: "op1", name: "spec", type_name: "BuildingType",
                                      owner_id: "o1", direction: "inout")
          ]
        )
      ]
    )
  end

  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [Ea::Model::Package.new(id: "p1", name: "Root")],
      classifiers: [klass],
      diagrams: [
        Ea::Model::Diagram.new(
          id: "d1",
          name: "Context Diagram: Building",
          diagram_type: "logical",
          elements: [
            Ea::Model::DiagramElement.new(
              id: "de1",
              model_element_ref: "c1",
              bounds: Ea::Model::Bounds.new(x: 10, y: 10, width: 60, height: 100),
              image_bounds: Ea::Model::Bounds.new(x: 10, y: 10, width: 60, height: 100),
              font_family: "Calibri",
              font_size: 13
            )
          ]
        )
      ]
    )
  end

  let(:diagram) { document.diagrams.first }
  let(:renderer) { described_class.new(diagram, model_index: document.index_by_id) }
  let(:svg) { renderer.render }
  let(:element) { diagram.elements.first }
  let(:font) do
    Ea::Svg::EaEmitter::FontResolver.new(diagram, theme: diagram.theme)
  end

  it "grows the drawn width to 22 + widest op row + 3" do
    row = "register(BuildingType*): Building"
    tl = Ea::Fonts::Metrics.text_length(row, font.size_for(element),
                                        family: font.family_for(element),
                                        weight: "400").round
    expect(svg).to include(%(width="#{22 + tl + 3}" height=))
  end

  it "keeps the stored width when it already fits the widest row" do
    row = "register(BuildingType*): Building"
    tl = Ea::Fonts::Metrics.text_length(row, font.size_for(element),
                                        family: font.family_for(element),
                                        weight: "400").round
    wide = 22 + tl + 3 + 40
    document.diagrams.first.elements.first.bounds.width = wide
    document.diagrams.first.elements.first.image_bounds.width = wide
    expect(renderer.render).to include(%(width="#{wide}" height=))
  end
end
