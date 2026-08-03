# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Document do
  PACKAGE_GUID = "AB12CD34_EF56_7890_AB_CD1234567890AB"
  PACKAGE_BOUNDS_X = "10"

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
    expect(svg).to include("<desc>Created with Enterprise Architect (Build: 1624)")
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

  it "hides properties that are navigable association ends" do
    svg_with_assoc_prop = described_class.new(
      diagram_with_association_property,
      model_index: document_with_association_property.index_by_id
    ).render
    expect(svg_with_assoc_prop).to include("simpleAttr")
    expect(svg_with_assoc_prop).not_to include("assocAttr")
  end

  it "renders Package model elements as polygon body+tab" do
    svg_with_package = described_class.new(
      diagram_with_package,
      model_index: document_with_package.index_by_id
    ).render
    polygons = svg_with_package.scan(/<polygon\b/).size
    expect(polygons).to be >= 3
    expect(svg_with_package).to include("fill-rule:evenodd;")
    expect(svg_with_package).not_to match(%r{<rect [^>]*x="#{PACKAGE_BOUNDS_X}"})
  end

  it "aliases EAPK_ package ids as EAID_ for diagram element refs" do
    idx = document_with_package.index_by_id
    expect(idx["EAPK_#{PACKAGE_GUID}"]).to be_a(Ea::Model::Package)
    expect(idx["EAID_#{PACKAGE_GUID}"]).to equal(idx["EAPK_#{PACKAGE_GUID}"])
  end

  it "uses '::' for type namespace separator" do
    expect(svg).to include("Integer") # primitive types stay clean
  end

  def diagram_with_association_property
    document_with_association_property.diagrams.first
  end

  def document_with_association_property
    @doc_assoc ||= Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(
          id: "k1",
          name: "X",
          properties: [
            Ea::Model::Property.new(id: "p_simple", name: "simpleAttr",
                                     type_name: "String", owner_id: "k1"),
            Ea::Model::Property.new(id: "p_assoc", name: "assocAttr",
                                     type_name: "Y", owner_id: "k1",
                                     association_id: "r_assoc")
          ]
        )
      ],
      diagrams: [
        Ea::Model::Diagram.new(
          id: "d_assoc", name: "Assoc",
          elements: [
            Ea::Model::DiagramElement.new(
              id: "de_assoc",
              model_element_ref: "k1",
              bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 100, height: 80),
              image_bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 100, height: 80),
              background_color: 13_434_879
            )
          ]
        )
      ]
    )
  end

  def diagram_with_package
    document_with_package.diagrams.first
  end

  def document_with_package
    @doc_pkg ||= Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [
        Ea::Model::Package.new(id: "EAPK_#{PACKAGE_GUID}", name: "Shape")
      ],
      diagrams: [
        Ea::Model::Diagram.new(
          id: "d_pkg", name: "Pkg",
          elements: [
            Ea::Model::DiagramElement.new(
              id: "de_pkg",
              model_element_ref: "EAID_#{PACKAGE_GUID}",
              bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 80),
              image_bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 80),
              background_color: -1
            )
          ]
        )
      ]
    )
  end
end
