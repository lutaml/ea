# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Document do
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [Ea::Model::Package.new(id: "p1", name: "Root")],
      classifiers: [
        Ea::Model::Klass.new(
          id: "c1",
          name: "Building",
          package_id: "p1",
          stereotype_refs: ["FeatureType"],
          properties: [
            Ea::Model::Property.new(id: "p1", name: "height", type_name: "Integer",
                                     owner_id: "c1")
          ]
        )
      ],
      diagrams: [
        Ea::Model::Diagram.new(
          id: "d1",
          name: "Overview",
          diagram_type: "logical",
          elements: [
            Ea::Model::DiagramElement.new(
              id: "de1",
              model_element_ref: "c1",
              bounds: Ea::Model::Bounds.new(x: 10, y: 10, width: 200, height: 80),
              image_bounds: Ea::Model::Bounds.new(x: 10, y: 10, width: 200, height: 80),
              background_color: 13_434_879, # BCol stored BGR: 0xCCFFFF → decodes to #FFFFCC
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

  it "emits XML declaration and DOCTYPE matching EA" do
    expect(svg).to start_with("<?xml version=\"1.0\"")
    expect(svg).to include("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\"")
  end

  it "emits root svg with cm width and height" do
    expect(svg).to match(/width="\d+\.\d{2}cm"/)
    expect(svg).to match(/height="\d+\.\d{2}cm"/)
    expect(svg).to include("viewBox=")
  end

  it "includes the EA build marker in <desc>" do
    expect(svg).to include("<desc>Created with Enterprise Architect (Build: 1628)")
  end

  it "renders a white background rect" do
    expect(svg).to include("fill:#FFFFFF;fill-opacity:1.00;")
    expect(svg).to include("<rect ")
  end

  it "renders the classifier shape with its decoded BCol fill" do
    expect(svg).to include("fill:#FFFFCC") # FFCCFF BGR → yellow RGB
  end

  it "renders the classifier name as text" do
    expect(svg).to include(">Building<")
  end

  it "renders attribute text under the classifier" do
    expect(svg).to include("height")
    expect(svg).to include("Integer")
  end
end
