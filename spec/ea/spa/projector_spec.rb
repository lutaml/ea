# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Spa::Projector do
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "Test", source_format: "qea"),
      packages: [
        Ea::Model::Package.new(id: "p1", name: "Root", qualified_name: "Root"),
        Ea::Model::Package.new(id: "p2", name: "Sub", parent_id: "p1",
                               qualified_name: "Root::Sub")
      ],
      classifiers: [
        Ea::Model::Klass.new(
          id: "c1", name: "Building", package_id: "p1",
          qualified_name: "Root::Building",
          properties: [
            Ea::Model::Property.new(id: "prop1", name: "height",
                                    type_name: "Integer",
                                    owner_id: "c1")
          ],
          annotations: [
            Ea::Model::Annotation.new(id: "an1", kind: "documentation",
                                      body: "A physical building.")
          ]
        ),
        Ea::Model::Enumeration.new(
          id: "e1", name: "Status", package_id: "p2",
          qualified_name: "Root::Sub::Status",
          literals: [
            Ea::Model::EnumerationLiteral.new(id: "l1", name: "Active",
                                              value: "active", ordinal: 0)
          ]
        )
      ]
    )
  end

  let(:projector) { described_class.new(document) }

  describe "#skeleton" do
    it "exposes metadata as a JSON-shaped hash" do
      expect(projector.skeleton.metadata["title"]).to eq("Test")
      expect(projector.skeleton.metadata["sourceFormat"]).to eq("qea")
    end

    it "builds a package tree with root and sub-packages" do
      tree = projector.skeleton.package_tree
      expect(tree.root_ids).to eq(%w[p1])
      sub = tree.nodes.find { |n| n.id == "p2" }
      expect(sub.parent_id).to eq("p1")
    end

    it "lists classifiers under their containing package in the tree" do
      tree = projector.skeleton.package_tree
      root = tree.nodes.find { |n| n.id == "p1" }
      expect(root.classifier_ids).to include("c1")
    end

    it "emits a skeleton entry per classifier with shard_url" do
      entries = projector.skeleton.entries
      expect(entries.map(&:id)).to contain_exactly("c1", "e1")

      klass_entry = entries.find { |e| e.id == "c1" }
      expect(klass_entry.kind).to eq("class")
      expect(klass_entry.shard_url).to eq("data/classes/c1.json")
    end

    it "uses custom shard_url_for when provided" do
      projector = described_class.new(
        document,
        shard_url_for: ->(el) { "/api/v1/#{el.id}.json" }
      )
      entry = projector.skeleton.entries.first
      expect(entry.shard_url).to eq("/api/v1/#{entry.id}.json")
    end
  end

  describe "#search_index" do
    it "includes one entry per classifier, property, and package" do
      entries = projector.search_index.entries
      ids = entries.map(&:id)
      expect(ids).to include("c1", "e1", "prop1", "p1", "p2")
    end

    it "boosts classifiers higher than properties" do
      entries = projector.search_index.entries
      klass = entries.find { |e| e.id == "c1" }
      prop = entries.find { |e| e.id == "prop1" }
      expect(klass.boost).to be > prop.boost
    end

    it "folds annotation bodies into the content field" do
      entries = projector.search_index.entries
      klass = entries.find { |e| e.id == "c1" }
      expect(klass.content).to include("physical building")
    end
  end

  describe "#shard_for" do
    it "produces a Shard with id, kind, and payload" do
      klass = document.classifiers.first
      shard = projector.shard_for(klass)
      expect(shard.id).to eq("c1")
      expect(shard.kind).to eq("class")
      expect(shard.payload["name"]).to eq("Building")
      expect(shard.payload["properties"].first["name"]).to eq("height")
    end

    it "preserves enumeration literals in the payload" do
      enum = document.classifiers.find { |c| c.is_a?(Ea::Model::Enumeration) }
      shard = projector.shard_for(enum)
      expect(shard.payload["literals"].first["value"]).to eq("active")
    end
  end

  describe "#each_shard" do
    it "yields one shard per classifier, package, and diagram" do
      shards = projector.each_shard.to_a
      ids = shards.map(&:id)
      expect(ids).to include("c1", "e1", "p1", "p2")
    end
  end
end
