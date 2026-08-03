# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel do
  let(:dependency) do
    Ea::Model::Dependency.new(id: "dep1", client_id: "c1",
                              supplier_id: "c2", stereotype: "import")
  end
  let(:association) do
    Ea::Model::Association.new(id: "assoc1", source_id: "c1", target_id: "c2")
  end
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [dependency, association]
    )
  end
  let(:model_index) { document.index_by_id }

  def renderer
    described_class.new(canvas: nil, model_index: model_index,
                        font_family: "Carlito", font_size: 7, font_unit: "pt")
  end

  def connector_for(relationship)
    Ea::Model::DiagramConnector.new(
      id: "dc_#{relationship.id}",
      relationship_ref: relationship.id,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
  end

  it "returns «stereotype» for a connector with an applied stereotype" do
    expect(renderer.stereotype_label(connector_for(dependency)))
      .to eq("«import»")
  end

  it "renders the stereotype text at the connector midpoint" do
    out = renderer.text_for(connector_for(dependency),
                             [[0, 0], [100, 0]])
    expect(out).to include("«import»")
    expect(out).to include('x="50') # midpoint of [0,0]–[100,0]
  end

  it "returns nil for a relationship without stereotype" do
    bare_dep = Ea::Model::Dependency.new(id: "dep2", client_id: "c1",
                                          supplier_id: "c2")
    doc = Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [bare_dep]
    )
    r = described_class.new(canvas: nil, model_index: doc.index_by_id,
                            font_family: "Carlito", font_size: 7, font_unit: "pt")
    expect(r.stereotype_label(connector_for(bare_dep))).to be_nil
  end

  it "returns nil for an association (handled by EndLabel)" do
    expect(renderer.stereotype_label(connector_for(association))).to be_nil
  end
end
