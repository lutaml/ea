# frozen_string_literal: true

require "spec_helper"
require "ea"

# EA keeps the canvas open around each connector end-label box: its left
# is the text x, its top the first baseline less the rounded font height,
# its size the stored CX/CY (+5 on the canvas). Checked on the PLATEAU
# QEA diagrams AC2191E3, 88AF6BD7 (right) and 95246DCF (bottom).
RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel do
  let(:property) do
    Ea::Model::Property.new(id: "p_src", name: "items", owner_id: "c1",
                            visibility: "public", multiplicity_lower: 0,
                            multiplicity_upper: -1)
  end
  let(:association) do
    Ea::Model::Association.new(id: "r1", source_id: "p_src", target_id: "p_tgt")
  end
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [Ea::Model::Klass.new(id: "c1", name: "A", properties: [property])],
      relationships: [association]
    )
  end
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "dc1", relationship_ref: association.id,
      connector_type: "Association", direction: "Source -> Destination",
      source_stereotype: "Property",
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
  end
  let(:renderer) do
    described_class.new(canvas: nil, model_index: document.index_by_id,
                        document: document, theme: Ea::Theme::Registry.default,
                        font_family: "Carlito", font_size: 7, font_unit: "pt")
  end

  def emit(text_box, mult_box)
    renderer.texts(text_box: text_box, mult_box: mult_box, anchor: [0, 0],
                   connector: connector, end_kind: :source)
  end

  it "reports no reach before a label is emitted" do
    expect(renderer.reach).to be_nil
  end

  it "reaches the role box's x + CX and top + CY" do
    out = emit({ "ox" => 10, "oy" => 15, "cx" => 136, "cy" => 35 },
               { "ox" => 0, "oy" => 0 })
    role_x, role_y = out.first.match(/x="(-?[\d.]+)" y="(-?[\d.]+)"/).captures.map(&:to_f)

    expect(renderer.reach).to eq([role_x + 136, role_y - 10 + 35])
  end

  it "takes the farthest of the role and multiplicity boxes" do
    emit({ "ox" => 10, "oy" => 15, "cx" => 20, "cy" => 10 },
         { "ox" => 0, "oy" => 0, "cx" => 19, "cy" => 40 })

    expect(renderer.reach).to eq([31, 45])
  end

  it "ignores boxes that carry no stored size" do
    emit({ "ox" => 10, "oy" => 15 }, { "ox" => 0, "oy" => 0 })

    expect(renderer.reach).to be_nil
  end
end
