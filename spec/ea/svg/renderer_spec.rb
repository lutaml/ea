# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::Renderer do
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [Ea::Model::Package.new(id: "p1", name: "Root")],
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "Building", package_id: "p1"),
        Ea::Model::Klass.new(id: "c2", name: "Floor", package_id: "p1")
      ],
      diagrams: [
        Ea::Model::Diagram.new(
          id: "d1",
          name: "Overview",
          diagram_type: "logical",
          bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 1000, height: 800),
          elements: [
            Ea::Model::DiagramElement.new(
              id: "de1",
              model_element_ref: "c1",
              bounds: Ea::Model::Bounds.new(x: 100, y: 100, width: 200, height: 80),
              style: { bcol: "16777215", lcol: "0", lwd: "1" }
            ),
            Ea::Model::DiagramElement.new(
              id: "de2",
              model_element_ref: "c2",
              bounds: Ea::Model::Bounds.new(x: 500, y: 100, width: 200, height: 80)
            )
          ],
          connectors: [
            Ea::Model::DiagramConnector.new(
              id: "dc1",
              relationship_ref: "r1",
              source_element_ref: "de1",
              target_element_ref: "de2",
              waypoints: [
                Ea::Model::Waypoint.new(
                  position: Ea::Model::Point.new(x: 300, y: 140)
                ),
                Ea::Model::Waypoint.new(
                  position: Ea::Model::Point.new(x: 500, y: 140)
                )
              ]
            )
          ]
        )
      ]
    )
  end

  let(:diagram) { document.diagrams.first }
  let(:renderer) { described_class.new(diagram, model_index: document.index_by_id) }
  let(:svg) { renderer.render }

  it "emits a standalone XML SVG document" do
    expect(svg).to start_with("<?xml version=\"1.0\"")
    expect(svg).to include("<svg xmlns=\"http://www.w3.org/2000/svg\"")
  end

  it "renders one <rect> per element plus the background" do
    # background + 2 elements
    expect(svg.scan(/<rect\b/).size).to eq(3)
  end

  it "renders one <path> per connector with waypoint coordinates" do
    expect(svg.scan(/<path\b/).size).to be >= 1
    expect(svg).to include("300")
    expect(svg).to include("140")
    expect(svg).to include("500")
  end

  it "labels each element with the bound model element's name" do
    expect(svg).to include(">Building<")
    expect(svg).to include(">Floor<")
  end

  it "includes padding around the drawing area" do
    # Elements span x=100..700, y=100..180. With padding 20:
    # viewBox should be "80 80 640 120"
    expect(svg).to match(/viewBox="80 80 640 120"/)
  end
end
