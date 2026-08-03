# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Labels do
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
  let(:target_property) do
    Ea::Model::Property.new(
      id: "p_tgt",
      name: "owner",
      owner_id: "c2",
      visibility: "public",
      multiplicity_lower: 0,
      multiplicity_upper: 1
    )
  end
  let(:classifier_a) do
    Ea::Model::Klass.new(id: "c1", name: "A", properties: [source_property])
  end
  let(:classifier_b) do
    Ea::Model::Klass.new(id: "c2", name: "B", properties: [target_property])
  end
  let(:relationship) do
    Ea::Model::Association.new(
      id: "r1",
      source_id: "p_src",
      target_id: "p_tgt"
    )
  end
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "dc1",
      relationship_ref: relationship.id,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ],
      label_boxes: {
        llb: { "ox" => 0, "oy" => 30 },
        llt: { "ox" => 10, "oy" => 15 }
      }
    )
  end
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [classifier_a, classifier_b],
      relationships: [relationship],
      diagrams: [Ea::Model::Diagram.new(id: "d1", name: "D", connectors: [connector])]
    )
  end
  let(:diagram) { document.diagrams.first }
  let(:renderer) { described_class.new(diagram, model_index: document.index_by_id) }

  it "emits role name text for the source-end label" do
    out = renderer.render
    expect(out).to include("+items")
  end

  it "emits multiplicity text" do
    out = renderer.render
    expect(out).to include("0..*")
  end

  context "when association has no properties" do
    let(:relationship) do
      Ea::Model::Association.new(id: "r1", source_id: "x", target_id: "y")
    end

    it "emits no labels" do
      expect(renderer.render).to eq("")
    end
  end

  context "when label boxes are absent" do
    let(:connector) do
      Ea::Model::DiagramConnector.new(
        id: "dc1",
        relationship_ref: relationship.id,
        waypoints: [
          Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
          Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
        ]
      )
    end

    it "emits no labels without geometry boxes (EA behavior)" do
      expect(renderer.render).to eq("")
    end
  end
end
