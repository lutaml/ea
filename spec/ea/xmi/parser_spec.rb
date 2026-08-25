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
end
