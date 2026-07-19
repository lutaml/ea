# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Model::Document do
  describe "polymorphic round-trip" do
    let(:document) do
      described_class.new(
        metadata: Ea::Model::Metadata.new(
          title: "Test Model",
          source_format: "qea",
          source_tool: "Sparx EA 16"
        ),
        packages: [
          Ea::Model::Package.new(id: "p1", name: "Root"),
          Ea::Model::Package.new(id: "p2", name: "Sub", parent_id: "p1")
        ],
        classifiers: [
          Ea::Model::Klass.new(id: "c1", name: "Building", package_id: "p1",
                               is_abstract: false),
          Ea::Model::Enumeration.new(
            id: "e1",
            name: "Status",
            package_id: "p2",
            literals: [
              Ea::Model::EnumerationLiteral.new(
                id: "l1", name: "Active", value: "active", ordinal: 0
              ),
              Ea::Model::EnumerationLiteral.new(
                id: "l2", name: "Inactive", value: "inactive", ordinal: 1
              )
            ]
          ),
          Ea::Model::DataType.new(id: "d1", name: "Measure", package_id: "p2"),
          Ea::Model::Interface.new(id: "i1", name: "Drawable", package_id: "p1")
        ],
        relationships: [
          Ea::Model::Generalization.new(id: "g1", specific_id: "c1",
                                        general_id: "d1"),
          Ea::Model::Association.new(id: "a1", source_id: "c1",
                                     target_id: "d1"),
          Ea::Model::Realization.new(id: "rz1", realizing_id: "c1",
                                     contract_id: "i1"),
          Ea::Model::Dependency.new(id: "dp1", client_id: "c1",
                                    supplier_id: "e1")
        ]
      )
    end

    it "round-trips through JSON preserving classifier subclasses" do
      json = document.to_json
      round_trip = described_class.from_json(json)

      expect(round_trip.classifiers.map(&:class).map(&:name))
        .to contain_exactly(
          "Ea::Model::Klass",
          "Ea::Model::Enumeration",
          "Ea::Model::DataType",
          "Ea::Model::Interface"
        )
    end

    it "round-trips through JSON preserving relationship subclasses" do
      json = document.to_json
      round_trip = described_class.from_json(json)

      expect(round_trip.relationships.map(&:class).map(&:name))
        .to contain_exactly(
          "Ea::Model::Generalization",
          "Ea::Model::Association",
          "Ea::Model::Realization",
          "Ea::Model::Dependency"
        )
    end

    it "preserves enumeration literals through round-trip" do
      json = document.to_json
      round_trip = described_class.from_json(json)
      enum = round_trip.classifiers.find { |c| c.is_a?(Ea::Model::Enumeration) }

      expect(enum.literals.map(&:name)).to eq(%w[Active Inactive])
      expect(enum.literals.map(&:ordinal)).to eq([0, 1])
    end
  end

  describe "#index_by_id" do
    it "indexes every package, classifier, and relationship by id" do
      document = described_class.new(
        packages: [Ea::Model::Package.new(id: "p1", name: "Root")],
        classifiers: [Ea::Model::Klass.new(id: "c1", name: "A")],
        relationships: [
          Ea::Model::Generalization.new(id: "g1", specific_id: "c1",
                                        general_id: "c1")
        ]
      )

      idx = document.index_by_id
      expect(idx.keys).to contain_exactly("p1", "c1", "g1")
    end

    it "memoizes the index across calls" do
      document = described_class.new(
        classifiers: [Ea::Model::Klass.new(id: "c1", name: "A")]
      )

      first = document.index_by_id
      second = document.index_by_id
      expect(first).to be(second)
    end
  end

  describe "#root_packages" do
    it "returns packages with no parent_id" do
      document = described_class.new(
        packages: [
          Ea::Model::Package.new(id: "p1", name: "Root"),
          Ea::Model::Package.new(id: "p2", name: "Sub", parent_id: "p1")
        ]
      )

      expect(document.root_packages.map(&:id)).to eq(%w[p1])
    end
  end

  describe "#classifiers_in_package" do
    it "returns classifiers whose package_id matches" do
      document = described_class.new(
        classifiers: [
          Ea::Model::Klass.new(id: "c1", name: "A", package_id: "p1"),
          Ea::Model::Klass.new(id: "c2", name: "B", package_id: "p2"),
          Ea::Model::Klass.new(id: "c3", name: "C", package_id: "p1")
        ]
      )

      expect(document.classifiers_in_package("p1").map(&:id))
        .to contain_exactly("c1", "c3")
    end
  end

  describe "#relationships_for" do
    let(:document) do
      described_class.new(
        classifiers: [
          Ea::Model::Klass.new(id: "c1", name: "A"),
          Ea::Model::Klass.new(id: "c2", name: "B"),
          Ea::Model::Klass.new(id: "c3", name: "C")
        ],
        relationships: [
          Ea::Model::Association.new(id: "a1", source_id: "c1",
                                     target_id: "c2"),
          Ea::Model::Generalization.new(id: "g1", specific_id: "c2",
                                        general_id: "c3")
        ]
      )
    end

    it "returns associations touching the classifier on either end" do
      expect(document.relationships_for("c1").map(&:id)).to eq(%w[a1])
      expect(document.relationships_for("c2").map(&:id))
        .to contain_exactly("a1", "g1")
    end

    it "returns generalizations where classifier is specific or general" do
      expect(document.relationships_for("c3").map(&:id)).to eq(%w[g1])
    end
  end
end
