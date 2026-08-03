# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel do
  let(:source_property) do
    Ea::Model::Property.new(
      id: "p_src",
      name: "items",
      owner_id: "c1",
      visibility: "public",
      multiplicity_lower: 0,
      multiplicity_upper: -1
    )
  end
  let(:classifier_a) do
    Ea::Model::Klass.new(id: "c1", name: "A", properties: [source_property])
  end
  let(:association) do
    Ea::Model::Association.new(id: "r1", source_id: "p_src", target_id: "p_tgt")
  end
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [classifier_a],
      relationships: [association]
    )
  end
  let(:model_index) { document.index_by_id }
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "dc1",
      relationship_ref: association.id,
      connector_type: "Association",
      direction: "Source -> Destination",
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ],
      label_boxes: {
        llb: { "ox" => 0, "oy" => 0 },
        llt: { "ox" => 10, "oy" => 15 }
      }
    )
  end

  def renderer
    described_class.new(canvas: nil, model_index: model_index,
                        document: document, theme: Ea::Theme::Registry.default,
                        font_family: "Carlito", font_size: 7, font_unit: "pt")
  end

  it "emits role name + «property» + multiplicity at the source box" do
    out = renderer.texts(text_box: { "ox" => 10, "oy" => 15 },
                          mult_box: { "ox" => 0, "oy" => 0 },
                          anchor: [0, 0], connector: connector,
                          end_kind: :source)
    joined = out.join
    expect(joined).to include("+items")
    expect(joined).to include("«property»")
    expect(joined).to include("0..*")
  end

  it "returns [] when no text or mult box is positioned" do
    out = renderer.texts(text_box: nil, mult_box: nil,
                          anchor: [0, 0], connector: connector,
                          end_kind: :source)
    expect(out).to eq([])
  end

  it "falls back to the opposite-end role when source end has none" do
    # Target-only role: the association has only a target_role_name
    # set, no source role. Only the source-side LLT box exists.
    # EndLabel should render the target-side role at the source box.
    target_only_assoc = Ea::Model::Association.new(
      id: "r2",
      source_id: "c1",
      target_id: "c2",
      source_role_name: nil,
      target_role_name: "things",
      target_multiplicity_lower: 0,
      target_multiplicity_upper: 1
    )
    doc = Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [target_only_assoc]
    )
    conn = Ea::Model::DiagramConnector.new(
      id: "dc2",
      relationship_ref: target_only_assoc.id,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
    r = described_class.new(canvas: nil, model_index: doc.index_by_id,
                            document: doc, theme: Ea::Theme::Registry.default,
                            font_family: "Carlito", font_size: 7, font_unit: "pt")
    out = r.texts(text_box: { "ox" => 5, "oy" => 5 },
                  mult_box: nil, anchor: [0, 0], connector: conn,
                  end_kind: :source)
    expect(out.join).to include("+things")
  end
end
