# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe Ea::Mdg::StereotypeAliasRegistry do
  describe ".from_nokogiri" do
    it "maps canonical name and aliases to canonical form" do
      xml = <<~XML
        <Stereotypes>
          <Stereotype name="FeatureType">
            <Alias>Feature Type</Alias>
            <Alias>featureType</Alias>
            <Alias>featuretype</Alias>
          </Stereotype>
          <Stereotype name="DataType">
            <Alias>dataType</Alias>
          </Stereotype>
        </Stereotypes>
      XML
      registry = described_class.from_nokogiri(Nokogiri::XML(xml))

      expect(registry.canonicalize("featureType")).to eq("FeatureType")
      expect(registry.canonicalize("FEATURETYPE")).to eq("FeatureType")
      expect(registry.canonicalize("featuretype")).to eq("FeatureType")
      expect(registry.canonicalize("Feature Type")).to eq("FeatureType")
      expect(registry.canonicalize("dataType")).to eq("DataType")
    end

    it "passes through unknown stereotypes unchanged" do
      registry = described_class.from_nokogiri(Nokogiri::XML("<Stereotypes/>"))
      expect(registry.canonicalize("UnknownStereo")).to eq("UnknownStereo")
    end

    it "returns nil for nil input" do
      registry = described_class.new
      expect(registry.canonicalize(nil)).to be_nil
      expect(registry.canonicalize("")).to be_nil
    end

    it "lists canonical names uniquely" do
      xml = <<~XML
        <Stereotypes>
          <Stereotype name="FeatureType">
            <Alias>featureType</Alias>
            <Alias>featuretype</Alias>
          </Stereotype>
          <Stereotype name="Type">
            <Alias>type</Alias>
          </Stereotype>
        </Stereotypes>
      XML
      registry = described_class.from_nokogiri(Nokogiri::XML(xml))
      expect(registry.canonical_names.sort).to eq(%w[FeatureType Type])
    end
  end

  describe ".from_path" do
    it "returns empty registry for missing file" do
      registry = described_class.from_path("/nonexistent.xml")
      expect(registry.canonical_names).to eq([])
    end

    it "loads the bundled GMLStereotypes fixture" do
      path = "spec/fixtures/mdg/ea_config/gml/GMLStereotypes.xml"
      skip "fixture not present" unless File.exist?(path)

      registry = described_class.from_path(path)
      expect(registry.canonicalize("featuretype")).to eq("FeatureType")
      expect(registry.canonicalize("applicationSchema")).to eq("ApplicationSchema")
      expect(registry.canonical_names).to include("FeatureType", "DataType", "Type")
    end
  end
end
