# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"

# Validates the XMI → Ea::Model harmonization. The basic.xmi
# fixture is a small hand-crafted EA XMI export that exercises
# the common element types (Class, Package, Association,
# Dependency, Diagram).
RSpec.describe Ea::Sources::Xmi::Adapter do
  XMI_FIXTURE = fixtures_path("basic.xmi")
  skip_reason = "XMI fixture not available at #{XMI_FIXTURE}" unless File.exist?(XMI_FIXTURE)

  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(XMI_FIXTURE)) }
  let(:adapter) { described_class.new(root, XMI_FIXTURE) }
  let(:document) { adapter.to_document }

  before(:all) { skip skip_reason if skip_reason }

  describe "structural harmonization" do
    it "harmonizes every uml:Package as a Model::Package" do
      package_count = count_elements(root.model, "uml:Package")
      expect(document.packages.size).to eq(package_count)
    end

    it "harmonizes every uml:Class as a Model::Klass" do
      class_count = count_elements(root.model, "uml:Class")
      classes = document.classifiers.select { |c| c.is_a?(Ea::Model::Klass) }
      expect(classes.size).to eq(class_count)
    end

    it "harmonizes every uml:Association as a Model::Association" do
      assoc_count = count_elements(root.model, "uml:Association")
      associations = document.relationships.select { |r| r.is_a?(Ea::Model::Association) }
      expect(associations.size).to eq(assoc_count)
    end

    it "harmonizes every uml:Dependency as a Model::Dependency" do
      dep_count = count_elements(root.model, "uml:Dependency")
      deps = document.relationships.select { |r| r.is_a?(Ea::Model::Dependency) }
      expect(deps.size).to eq(dep_count)
    end
  end

  describe "classifier harmonization" do
    it "preserves properties on classes that have them" do
      klass_with_props = document.classifiers.find { |c| c.properties.any? }
      expect(klass_with_props).not_to be_nil
      expect(klass_with_props.properties.first).to be_a(Ea::Model::Property)
    end

    it "captures property type_name from the uml_type idref" do
      klass = document.classifiers.find { |c| c.properties.any? }
      prop = klass.properties.first
      expect(prop.type_name).to be_a(String)
    end

    it "every classifier has a non-empty id" do
      document.classifiers.each do |c|
        expect(c.id).to be_a(String)
        expect(c.id).not_to be_empty
      end
    end
  end

  describe "association harmonization" do
    it "captures source and target ends" do
      assoc = document.relationships.find { |r| r.is_a?(Ea::Model::Association) }
      expect(assoc.source_id).to be_a(String)
      expect(assoc.target_id).to be_a(String)
    end
  end

  describe "metadata" do
    it "records source_format as xmi" do
      expect(document.metadata.source_format).to eq("xmi")
    end

    it "records source_path" do
      expect(document.metadata.source_path).to eq(XMI_FIXTURE)
    end
  end

  describe "round-trip stability" do
    it "serializes to JSON and back without losing classifiers" do
      json = document.to_json
      round_trip = Ea::Model::Document.from_json(json)

      expect(round_trip.classifiers.size).to eq(document.classifiers.size)
      expect(round_trip.relationships.size).to eq(document.relationships.size)
    end
  end

  # Helper: count packaged elements of a given xmi:type, walking the
  # tree depth-first.
  def count_elements(model_element, xmi_type, seen = 0)
    model_element.packaged_element.each do |pe|
      seen += 1 if pe.type == xmi_type
      seen = count_elements(pe, xmi_type, seen)
    end
    seen
  end
end
