# frozen_string_literal: true

require "spec_helper"
require "ea"

# EA's unframed export (the PLATEAU native SVGs) anchors the canvas on the
# drawn content: shapes 10 px from the edge, text boxes 5 px, the origin
# never beyond model -5. Measured on 220 native SVGs; see Canvas.
RSpec.describe "Unframed canvas origin" do
  def model_document(bounds)
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [Ea::Model::Package.new(id: "p1", name: "Root")],
      classifiers: [Ea::Model::Klass.new(id: "c1", name: "Building",
                                         package_id: "p1")],
      diagrams: [
        Ea::Model::Diagram.new(
          id: "d1", name: "Overview", diagram_type: "logical",
          elements: [Ea::Model::DiagramElement.new(
            id: "de1", model_element_ref: "c1", bounds: bounds,
            image_bounds: bounds
          )]
        )
      ]
    )
  end

  def render(left:, top:, frame:)
    bounds = Ea::Model::Bounds.new(x: left, y: top, width: 200, height: 100)
    document = model_document(bounds)
    Ea::Svg::EaEmitter::Document.new(document.diagrams.first,
                                     model_index: document.index_by_id,
                                     frame: frame,
                                     content_anchor: true).render
  end

  def class_rect(svg)
    svg.scan(/<rect x="(-?[\d.]+)" y="(-?[\d.]+)" width="(\d+)" height="(\d+)" rx/)
       .first.map(&:to_f)
  end

  def view_box(svg)
    svg.match(/viewBox="0 0 (\d+) (\d+)"/).captures.map(&:to_i)
  end

  it "draws the leftmost and topmost shape 10 px from the canvas edge" do
    svg = render(left: 100, top: 200, frame: false)

    expect(class_rect(svg).first(2)).to eq([10.0, 10.0])
    expect(view_box(svg).first).to eq(220)
  end

  it "stops the origin at model -5 so a shape at the model origin draws at 5" do
    svg = render(left: 0, top: 0, frame: false)

    expect(class_rect(svg).first(2)).to eq([5.0, 5.0])
  end

  it "keeps a shape left of the model origin on the canvas with its 10 px margin" do
    svg = render(left: -100, top: -50, frame: false)

    expect(class_rect(svg).first(2)).to eq([10.0, 10.0])
    expect(view_box(svg).first(2)).to eq([220, 138])
  end

  it "keeps the 10 px margin once the shape is 5 px or more from the origin" do
    expect(class_rect(render(left: 3, top: 5, frame: false)).first(2)).to eq([8.0, 10.0])
  end

  it "keeps the framed export on the 35/40 content origin" do
    svg = render(left: 100, top: 200, frame: true)

    expect(class_rect(svg).first(2)).to eq([35.0, 40.0])
  end
end

RSpec.describe Ea::Svg::EaEmitter::CanvasAnchor do
  let(:shapes) { [100, 100, 300, 200] }

  it "pulls the origin toward a text box 5 px from the edge" do
    canvas = described_class.measured(shapes, [20, 90, 60, 100], nil)

    expect(canvas.origin_x).to eq(15)
    expect(canvas.translate_x(20)).to eq(5)
    expect(canvas.translate_y(100)).to eq(15)
  end

  it "widens the canvas to a label that overhangs the shapes" do
    narrow = described_class.measured(shapes, nil, nil)
    wide = described_class.measured(shapes, nil, [400, 0])

    expect([narrow.width, wide.width]).to eq([220, 315])
  end

  it "keeps the canvas open 5 px below a label box that hangs under the shapes" do
    plain = described_class.measured(shapes, nil, [200, 150])
    low = described_class.measured(shapes, nil, [200, 400])

    expect([plain.height, low.height]).to eq([141, 315])
  end

  it "never narrows a canvas the shapes already set" do
    expect(described_class.measured(shapes, nil, [150, 150]).width).to eq(220)
  end
end
