# frozen_string_literal: true

require "spec_helper"
require "ea"

# Validates the QEA → Ea::Model harmonization against the plateau
# model fixture. We don't assert exact element names (those shift
# as the source model evolves) — instead, we assert structural
# properties that should hold for any valid QEA.
RSpec.describe Ea::Sources::Qea::Adapter do
  PLATEAU_V51 = "/Users/mulgogi/src/mn/plateau-model/20251010_current_plateau_v5.1.qea"
  skip_reason = "Plateau model fixture not available at #{PLATEAU_V51}" unless File.exist?(PLATEAU_V51)

  let(:database) { Ea.parse(PLATEAU_V51) }
  let(:adapter) { described_class.new(database, PLATEAU_V51) }
  let(:document) { adapter.to_document }

  before(:all) { skip skip_reason if skip_reason }

  describe "structural counts vs QEA stats" do
    it "harmonizes every package" do
      qea_packages = database.collections[:packages].size
      expect(document.packages.size).to eq(qea_packages)
    end

    it "harmonizes every connector as a Relationship" do
      qea_connectors = database.collections[:connectors].size
      expect(document.relationships.size).to eq(qea_connectors)
    end

    it "harmonizes every diagram" do
      qea_diagrams = database.collections[:diagrams].size
      expect(document.diagrams.size).to eq(qea_diagrams)
    end
  end

  describe "classifier harmonization" do
    it "produces Klass instances for EA Class objects" do
      classes = document.classifiers.select { |c| c.is_a?(Ea::Model::Klass) }
      expect(classes).not_to be_empty
    end

    it "preserves enumeration literals" do
      enums = document.classifiers.select { |c| c.is_a?(Ea::Model::Enumeration) }
      expect(enums).not_to be_empty
      enum_with_literals = enums.find { |e| !e.literals.empty? }
      expect(enum_with_literals.literals.first).to be_a(Ea::Model::EnumerationLiteral)
    end

    it "every classifier has a non-empty id" do
      document.classifiers.each do |c|
        expect(c.id).to match(/\A[0-9A-Fa-f-]{20,}\z/),
                        "classifier #{c.name.inspect} has suspicious id #{c.id.inspect}"
      end
    end

    it "every classifier references a known package by id" do
      package_ids = document.packages.map(&:id).to_set
      document.classifiers.each do |c|
        next if c.package_id.nil?

        expect(package_ids).to include(c.package_id),
                               "classifier #{c.name.inspect} references unknown package #{c.package_id}"
      end
    end
  end

  describe "relationship harmonization" do
    it "dispatches Association vs Generalization by Connector_Type" do
      associations = document.relationships.count { |r| r.is_a?(Ea::Model::Association) }
      generalizations = document.relationships.count { |r| r.is_a?(Ea::Model::Generalization) }
      expect(associations).to be > 0
      expect(generalizations).to be > 0
    end

    it "every relationship has an id and relationship_kind" do
      document.relationships.each do |r|
        expect(r.id).to be_a(String)
        expect(r.relationship_kind).to be_a(String)
      end
    end
  end

  describe "diagram harmonization (the EA value-add)" do
    it "captures element bounds in pixel coordinates" do
      diagram = document.diagrams.find do |d|
        d.elements.any? { |e| e.bounds&.width&.nonzero? }
      end
      expect(diagram).not_to be_nil, "no diagram has non-zero-size elements"

      elem = diagram.elements.find { |e| e.bounds&.width&.nonzero? }
      expect(elem.bounds).to be_a(Ea::Model::Bounds)
      # EA occasionally stores inverted rects (rectbottom < recttop);
      # the model preserves them faithfully. Assert non-zero size
      # rather than strict positivity.
      expect(elem.bounds.width).not_to eq(0)
    end

    it "captures connector waypoints" do
      diag_with_waypoints = document.diagrams.find do |d|
        d.connectors.any? { |c| !c.waypoints.empty? }
      end
      expect(diag_with_waypoints).not_to be_nil,
                                         "no diagram connector has waypoints"

      waypoint = diag_with_waypoints.connectors.find { |c| !c.waypoints.empty? }.waypoints.first
      expect(waypoint.position).to be_a(Ea::Model::Point)
      expect(waypoint.position.x).to be_an(Integer)
    end

    it "most diagram elements reference a known model element by id" do
      # EA diagrams include Note and Text objects whose t_object rows
      # aren't classifiers in our model. We assert that the
      # overwhelming majority of references resolve, not 100%.
      known_ids = document.index_by_id.keys.to_set
      total = 0
      resolved = 0
      document.diagrams.each do |d|
        d.elements.each do |e|
          next if e.model_element_ref.nil?

          total += 1
          resolved += 1 if known_ids.include?(e.model_element_ref)
        end
      end

      skip "no diagram elements with refs" if total.zero?

      ratio = resolved.to_f / total
      expect(ratio).to be > 0.8,
                       "only #{resolved}/#{total} diagram elements reference known ids"
    end
  end

  describe "annotation harmonization (the other EA value-add)" do
    it "captures non-empty notes as Annotation instances" do
      annotated = document.classifiers.find { |c| !c.annotations.empty? }
      expect(annotated).not_to be_nil, "no classifier has annotations"
      expect(annotated.annotations.first.body).to be_a(String)
    end
  end

  describe "metadata" do
    it "records source_format as qea" do
      expect(document.metadata.source_format).to eq("qea")
    end

    it "records source_path" do
      expect(document.metadata.source_path).to eq(PLATEAU_V51)
    end
  end

  describe "round-trip stability" do
    it "serializes to JSON and back without losing counts" do
      json = document.to_json
      round_trip = Ea::Model::Document.from_json(json)

      expect(round_trip.classifiers.size).to eq(document.classifiers.size)
      expect(round_trip.relationships.size).to eq(document.relationships.size)
      expect(round_trip.diagrams.size).to eq(document.diagrams.size)
    end
  end
end
