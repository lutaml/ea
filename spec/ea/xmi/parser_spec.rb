# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Xmi::Parser do
  let(:parser) { described_class.new }
  let(:fixture_path) { fixtures_path("associationclass.xmi") }
  let(:xmi_model) { Xmi::Sparx::Root.parse_xml(File.read(fixture_path)) }

  before { parser.parse(xmi_model) }

  describe "#fetch_connector_by_associationclass" do
    it "returns the connector whose associationclass matches the given id" do
      connector = parser.fetch_connector_by_associationclass("EAID_ASSOC_CLASS")
      expect(connector).not_to be_nil
      expect(connector.idref).to eq("EAID_CONN_1")
      expect(connector.name).to eq("Rel1")
    end

    it "returns nil when no connector has the given associationclass" do
      connector = parser.fetch_connector_by_associationclass("NON_EXISTENT")
      expect(connector).to be_nil
    end

    it "returns nil for a connector that has no associationclass set" do
      connector = parser.fetch_connector_by_associationclass(nil)
      expect(connector).to be_nil
    end
  end

  describe "#lookup_connector_def_by_associationclass" do
    it "returns the documentation value of the matching connector" do
      doc = parser.lookup_connector_def_by_associationclass("EAID_ASSOC_CLASS")
      expect(doc).to eq("Connection with associationclass")
    end

    it "returns nil when no connector matches" do
      doc = parser.lookup_connector_def_by_associationclass("NON_EXISTENT")
      expect(doc).to be_nil
    end
  end

  describe "data type generalization" do # rubocop:disable Metrics/BlockLength
    let(:fixture_path) { fixtures_path("datatype_generalization.xmi") }
    let(:document) { parser.parse(xmi_model) }
    let(:data_types) { document.packages.first.data_types }

    def data_type_named(collection, name)
      collection.find { |dt| dt.name == name }
    end

    it "builds generalization for uml:DataType elements that declare one" do
      data_type = data_type_named(data_types, "TexCoordGen")

      expect(data_type.generalization).not_to be_nil
      expect(data_type.generalization.has_general).to be true
      expect(data_type.generalization.general.name)
        .to eq("AbstractTextureParameterization")
      expect(data_type.association_generalization.size).to eq(1)
    end

    it "leaves generalization nil when the XMI has no generalization child" do
      data_type = data_type_named(data_types, "NoGen")

      expect(data_type.generalization).to be_nil
      expect(data_type.association_generalization).to be_empty
    end

    it "exposes generalization as a countable collection via liquid drops" do
      drop = described_class.serialize_to_liquid(fixture_path)
      types = drop.packages.first.data_types

      expect(data_type_named(types, "TexCoordGen").generalization.count)
        .to eq(1)
      expect(data_type_named(types, "NoGen").generalization.count).to eq(0)
    end
  end
end
