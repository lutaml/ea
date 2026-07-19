# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Model do
  describe Ea::Model::Klass do
    it "defaults model_kind to 'class'" do
      expect(described_class.new.model_kind).to eq("class")
    end

    it "defaults is_active to false" do
      expect(described_class.new.is_active).to eq(false)
    end

    it "inherits properties/operations/annotations from Classifier" do
      klass = described_class.new(
        id: "c1",
        name: "Building",
        properties: [Ea::Model::Property.new(id: "p1", name: "height")],
        operations: [Ea::Model::Operation.new(id: "o1", name: "demolish")],
        annotations: [
          Ea::Model::Annotation.new(id: "an1", kind: "documentation",
                                    body: "A building.")
        ]
      )

      expect(klass.properties.map(&:name)).to eq(%w[height])
      expect(klass.operations.map(&:name)).to eq(%w[demolish])
      expect(klass.annotations.map(&:body)).to eq(["A building."])
    end
  end

  describe Ea::Model::Enumeration do
    it "defaults model_kind to 'enumeration'" do
      expect(described_class.new.model_kind).to eq("enumeration")
    end

    it "owns literals compositionally" do
      enum = described_class.new(
        id: "e1",
        name: "Color",
        literals: [
          Ea::Model::EnumerationLiteral.new(id: "l1", name: "Red",
                                            value: "RED", ordinal: 0),
          Ea::Model::EnumerationLiteral.new(id: "l2", name: "Green",
                                            value: "GREEN", ordinal: 1)
        ]
      )

      expect(enum.literals.map(&:value)).to eq(%w[RED GREEN])
    end
  end

  describe Ea::Model::DataType, "and PrimitiveType, and Interface" do
    it "each carries a distinct model_kind" do
      expect(Ea::Model::DataType.new.model_kind).to eq("data_type")
      expect(Ea::Model::PrimitiveType.new.model_kind).to eq("primitive_type")
      expect(Ea::Model::Interface.new.model_kind).to eq("interface")
    end
  end

  describe Ea::Model::Association do
    it "exposes source and target ends with multiplicity and aggregation" do
      assoc = described_class.new(
        id: "a1",
        source_id: "c1",
        target_id: "c2",
        source_multiplicity_lower: 1,
        source_multiplicity_upper: 1,
        target_multiplicity_lower: 0,
        target_multiplicity_upper: -1,
        source_aggregation: "none",
        target_aggregation: "composite"
      )

      expect(assoc.source_id).to eq("c1")
      expect(assoc.target_multiplicity_upper).to eq(-1)
      expect(assoc.target_aggregation).to eq("composite")
      expect(assoc.relationship_kind).to eq("association")
    end
  end

  describe Ea::Model::Generalization do
    it "references specific and general by id" do
      gen = described_class.new(id: "g1", specific_id: "c1",
                                general_id: "c2")
      expect(gen.specific_id).to eq("c1")
      expect(gen.general_id).to eq("c2")
      expect(gen.relationship_kind).to eq("generalization")
    end
  end

  describe Ea::Model::Annotation do
    it "carries kind, body, author" do
      ann = described_class.new(
        id: "an1", kind: "documentation", body: "Hello", author: "rt"
      )
      expect(ann.kind).to eq("documentation")
      expect(ann.body).to eq("Hello")
    end
  end

  describe Ea::Model::TaggedValue do
    it "carries key, value, optional stereotype scope" do
      tv = described_class.new(id: "tv1", key: "version", value: "1.0")
      expect(tv.stereotype_ref).to be_nil

      scoped = described_class.new(
        id: "tv2", key: ".persistence", value: "true",
        stereotype_ref: "st1"
      )
      expect(scoped.stereotype_ref).to eq("st1")
    end
  end

  describe Ea::Model::Diagram do
    it "owns elements and connectors with coordinates" do
      diagram = described_class.new(
        id: "dg1",
        name: "Overview",
        diagram_type: "logical",
        bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 1000, height: 800),
        elements: [
          Ea::Model::DiagramElement.new(
            id: "de1",
            model_element_ref: "c1",
            bounds: Ea::Model::Bounds.new(x: 100, y: 100, width: 200, height: 80)
          )
        ],
        connectors: [
          Ea::Model::DiagramConnector.new(
            id: "dc1",
            relationship_ref: "a1",
            source_element_ref: "de1",
            target_element_ref: "de2",
            waypoints: [
              Ea::Model::Waypoint.new(
                position: Ea::Model::Point.new(x: 200, y: 140)
              ),
              Ea::Model::Waypoint.new(
                position: Ea::Model::Point.new(x: 400, y: 140)
              )
            ]
          )
        ]
      )

      expect(diagram.elements.first.bounds.width).to eq(200)
      expect(diagram.connectors.first.waypoints.map { |w| w.position.x })
        .to eq([200, 400])
    end
  end

  describe Ea::Model::Bounds, "and Point, Waypoint" do
    it "round-trip through JSON" do
      bounds = Ea::Model::Bounds.new(x: 1, y: 2, width: 3, height: 4)
      rt = Ea::Model::Bounds.from_json(bounds.to_json)
      expect([rt.x, rt.y, rt.width, rt.height]).to eq([1, 2, 3, 4])
    end
  end
end
