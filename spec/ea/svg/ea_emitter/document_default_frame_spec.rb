# frozen_string_literal: true

require "spec_helper"
require "ea"

# EA's own export draws no generated frame and anchors the canvas on the
# content. Document must do both when called with no frame option.
RSpec.describe Ea::Svg::EaEmitter::Document, "defaults" do
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 200, width: 200, height: 100) }
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [Ea::Model::Package.new(id: "p1", name: "Root")],
      classifiers: [Ea::Model::Klass.new(id: "c1", name: "Building", package_id: "p1")],
      diagrams: [
        Ea::Model::Diagram.new(
          id: "d1", name: "Overview", diagram_type: "logical",
          elements: [Ea::Model::DiagramElement.new(
            id: "de1", model_element_ref: "c1", bounds: bounds, image_bounds: bounds
          )]
        )
      ]
    )
  end
  let(:diagram) { document.diagrams.first }

  def class_rect(svg)
    svg.scan(/<rect x="(-?[\d.]+)" y="(-?[\d.]+)" width="(\d+)" height="(\d+)" rx/).first.map(&:to_f)
  end

  def view_box(svg)
    svg.match(/viewBox="0 0 (\d+) (\d+)"/).captures.map(&:to_i)
  end

  it "draws no diagram frame by default" do
    svg = described_class.new(diagram, model_index: document.index_by_id).render

    expect(svg).not_to include("class Overview")
  end

  it "anchors the canvas on the content by default: shape 10 px from the edge" do
    svg = described_class.new(diagram, model_index: document.index_by_id).render

    expect(class_rect(svg).first(2)).to eq([10.0, 10.0])
    expect(view_box(svg).first).to eq(220)
  end

  it "keeps the framed 35/40 content origin only when a frame is requested" do
    svg = described_class.new(diagram, model_index: document.index_by_id, frame: true).render

    expect(svg).to include("class Overview")
    expect(class_rect(svg).first(2)).not_to eq([10.0, 10.0])
  end
end
