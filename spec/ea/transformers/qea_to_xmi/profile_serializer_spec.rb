# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Transformers::QeaToXmi::ProfileSerializer do
  let(:mdg_path) { "spec/fixtures/mdg/CityGML_MDG_Technology.xml" }
  let(:document) { Ea::Mdg::Loader.from_path(mdg_path).document }
  let(:registry) do
    reg = Ea::Mdg::Registry.new
    reg.register(document)
    reg
  end

  describe "#call" do
    subject(:blocks) { described_class.new(registry).call }

    it "returns an Array of PackagedElement instances" do
      expect(blocks).to be_an(Array)
      expect(blocks).not_to be_empty
      expect(blocks).to all(be_a(::Xmi::Uml::PackagedElement))
    end

    it "includes one uml:Stereotype per MDG stereotype" do
      stereotypes = blocks.select { |b| b.type == "uml:Stereotype" }
      expect(stereotypes.size).to eq(document.stereotypes.size)
    end

    it "includes uml:Extension elements for each non-empty applies_to" do
      extensions = blocks.select { |b| b.type == "uml:Extension" }
      expected = document.stereotypes.sum { |s| s.applies_to.size }
      expect(extensions.size).to eq(expected)
    end
  end

  context "with no registry" do
    it "returns empty array" do
      expect(described_class.new(nil).call).to eq([])
    end
  end

  context "with empty registry" do
    it "returns empty array" do
      expect(described_class.new(Ea::Mdg::Registry.new).call).to eq([])
    end
  end

  describe "stereotype element shape" do
    let(:serializer) { described_class.new(registry) }
    let(:blocks) { serializer.call }
    let(:codelist) { blocks.find { |b| b.name == "CodeList" } }

    it "builds the stereotype with correct xmi:type" do
      expect(codelist.type).to eq("uml:Stereotype")
    end

    it "uses the stereotype name as xmi:id" do
      expect(codelist.id).to eq("CodeList")
    end

    it "emits a base_Class property" do
      base = codelist.owned_attribute.find { |a| a.name == "base_Class" }
      expect(base).not_to be_nil
      expect(base.id).to eq("CodeList-base_Class")
      expect(base.association).to eq("Class_CodeList")
    end

    it "emits one ownedAttribute per tagged value" do
      tv_attrs = codelist.owned_attribute.reject { |a| a.name.start_with?("base_") }
      mdg_stereo = document.stereotypes.find { |s| s.name == "CodeList" }
      expect(tv_attrs.size).to eq(mdg_stereo.tagged_values.size)
    end

    it "includes a type href for each tagged value" do
      as_dict = codelist.owned_attribute.find { |a| a.name == "asDictionary" }
      expect(as_dict.uml_type.href).to include("#Boolean")
    end
  end

  describe "extension element shape" do
    let(:serializer) { described_class.new(registry) }
    let(:blocks) { serializer.call }
    let(:class_codelist) { blocks.find { |b| b.id == "Class_CodeList" } }

    it "builds the extension with correct xmi:type" do
      expect(class_codelist.type).to eq("uml:Extension")
    end

    it "names the extension A_{metaclass}_{stereotype}" do
      expect(class_codelist.name).to eq("A_Class_CodeList")
    end

    it "has two memberEnds (extension end + base property)" do
      expect(class_codelist.member_ends.size).to eq(2)
    end

    it "has an ExtensionEnd owned end" do
      ext_end = class_codelist.owned_end.first
      expect(ext_end.type).to eq("uml:ExtensionEnd")
      expect(ext_end.id).to eq("extension_CodeList")
    end
  end

  describe "Lutaml::Model::GlobalRegister integration" do
    it "registers the MDG with lutaml-model when registered with Ea::Mdg::Registry" do
      # The registry fixture already registered CityGML
      found = Lutaml::Model::GlobalRegister.lookup(:ea_mdg_citygml)
      expect(found).not_to be_nil
      expect(found.id).to eq(:ea_mdg_citygml)
    end

    it "unregisters from lutaml-model when removed from Ea::Mdg::Registry" do
      registry.unregister("CityGML")
      expect(Lutaml::Model::GlobalRegister.lookup(:ea_mdg_citygml)).to be_nil
    end
  end

  describe "type normalization" do
    let(:serializer) { described_class.new(registry) }
    let(:blocks) { serializer.call }

    it "maps Boolean tagged values to UML Boolean type" do
      codelist = blocks.find { |b| b.name == "CodeList" }
      as_dict = codelist.owned_attribute.find { |a| a.name == "asDictionary" }
      expect(as_dict.uml_type.href).to end_with("#Boolean")
    end

    it "defaults unknown types to String" do
      codelist = blocks.find { |b| b.name == "CodeList" }
      encoding = codelist.owned_attribute.find { |a| a.name == "xsdEncodingRule" }
      expect(encoding.uml_type.href).to end_with("#String")
    end
  end
end
