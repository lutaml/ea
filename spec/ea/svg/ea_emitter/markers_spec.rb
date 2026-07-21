# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Markers do
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [relationship],
      diagrams: [
        Ea::Model::Diagram.new(
          id: "d1", name: "D",
          connectors: [
            Ea::Model::DiagramConnector.new(
              id: "dc1",
              relationship_ref: relationship.id,
              waypoints: [
                Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
                Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
              ]
            )
          ]
        )
      ]
    )
  end

  let(:diagram) { document.diagrams.first }
  let(:renderer) { described_class.new(diagram, model_index: document.index_by_id) }

  context "with a navigable Association" do
    let(:relationship) { Ea::Model::Association.new(id: "r1", source_id: "c1", target_id: "c2") }

    it "emits a filled triangle at the target end" do
      out = renderer.render
      expect(out).to include("fill:#000000")
      expect(out).to include("<polygon")
    end
  end

  context "with a Generalization" do
    let(:relationship) { Ea::Model::Generalization.new(id: "r1", specific_id: "c1", general_id: "c2") }

    it "emits an open (white-fill) triangle" do
      out = renderer.render
      expect(out).to include("fill:#FFFFFF")
      expect(out).to include("<polygon")
    end
  end
end
