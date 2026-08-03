# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Label::Registry do
  let(:association) do
    Ea::Model::Association.new(id: "a1", source_id: "c1", target_id: "c2")
  end
  let(:dependency) do
    Ea::Model::Dependency.new(id: "d1", client_id: "c1", supplier_id: "c2",
                              stereotype: "import")
  end
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [association, dependency]
    )
  end
  let(:model_index) { document.index_by_id }
  let(:registry) { described_class.new(model_index: model_index) }

  def connector_for(rel)
    Ea::Model::DiagramConnector.new(id: "dc_#{rel.id}",
                                      relationship_ref: rel.id)
  end

  it "identifies plain associations as end-label path" do
    expect(registry.association?(connector_for(association))).to be true
    expect(registry.midpoint?(connector_for(association))).to be nil
    expect(registry.end_label?(connector_for(association))).to be true
  end

  it "identifies stereotype-bearing non-association as midpoint path" do
    expect(registry.association?(connector_for(dependency))).to be false
    expect(registry.midpoint?(connector_for(dependency))).to eq("«import»")
    expect(registry.end_label?(connector_for(dependency))).to be false
  end

  it "routes stereotype-bearing associations to midpoint, not end-labels" do
    stereotyped_assoc = Ea::Model::Association.new(
      id: "sa1", source_id: "c1", target_id: "c2", stereotype: "import"
    )
    doc = Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [stereotyped_assoc]
    )
    r = described_class.new(model_index: doc.index_by_id)
    conn = Ea::Model::DiagramConnector.new(id: "dc_sa",
                                            relationship_ref: stereotyped_assoc.id)
    expect(r.midpoint?(conn)).to eq("«import»")
    expect(r.end_label?(conn)).to be false
  end
end
