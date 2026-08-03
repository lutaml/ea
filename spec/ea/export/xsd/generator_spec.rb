# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe Ea::Export::Xsd do
  describe "ClassMapping" do
    it "loads mappings from XML" do
      xml = <<~XML
        <ClassMapping>
          <Class name="FeatureType" element="featureMember"
                type="FeaturePropertyType" propertyType="..."
                typeContent="complex"/>
          <Class name="Integer" type="integer" propertyType="integer"
                typeContent="simple"/>
        </ClassMapping>
      XML
      mapping = described_class::ClassMapping.from_nokogiri(Nokogiri::XML(xml))

      ft = mapping.for("FeatureType")
      expect(ft).not_to be_nil
      expect(ft.element).to eq("featureMember")
      expect(ft.type).to eq("FeaturePropertyType")

      expect(mapping.for("Integer").type).to eq("integer")
      expect(mapping.for("Nonexistent")).to be_nil
    end

    it "returns empty mapping for missing file" do
      mapping = described_class::ClassMapping.from_path("/nonexistent.xml")
      expect(mapping.mappings).to be_empty
    end

    it "loads the bundled GML fixture" do
      path = "spec/fixtures/mdg/ea_config/gml/GMLClassMapping.xml"
      skip "fixture missing" unless File.exist?(path)

      mapping = described_class::ClassMapping.from_path(path)
      expect(mapping.for("Integer").type).to eq("integer")
      expect(mapping.for("CharacterString").type).to eq("string")
    end
  end

  describe "NamespaceRegistry" do
    it "extracts namespaces keyed by prefix" do
      xml = <<~XML
        <Namespaces>
          <GMLNS version="3.2.1">
            <Namespace xmlns="gml" targetNamespace="http://www.opengis.net/gml/3.2"
                       xsdDocument="http://schemas.opengis.net/gml/3.2.1/gml.xsd"/>
            <Namespace xmlns="xlink" targetNamespace="http://www.w3.org/1999/xlink"
                       xsdDocument=".../xlink.xsd"/>
          </GMLNS>
        </Namespaces>
      XML
      registry = described_class::NamespaceRegistry.from_nokogiri(Nokogiri::XML(xml))

      expect(registry.for("gml").target_namespace)
        .to eq("http://www.opengis.net/gml/3.2")
      expect(registry.for("xlink").xsd_document).to include("xlink.xsd")
      expect(registry.versions).to eq(["3.2.1"])
    end

    it "filters by version when requested" do
      xml = <<~XML
        <Namespaces>
          <GMLNS version="3.2.1">
            <Namespace xmlns="gml" targetNamespace="http://gml-3.2"/>
          </GMLNS>
          <GMLNS version="3.3">
            <Namespace xmlns="gml" targetNamespace="http://gml-3.3"/>
          </GMLNS>
        </Namespaces>
      XML
      r32 = described_class::NamespaceRegistry.from_nokogiri(Nokogiri::XML(xml), version: "3.2.1")
      r33 = described_class::NamespaceRegistry.from_nokogiri(Nokogiri::XML(xml), version: "3.3")

      expect(r32.for("gml").target_namespace).to eq("http://gml-3.2")
      expect(r33.for("gml").target_namespace).to eq("http://gml-3.3")
    end
  end

  describe "Generator" do
    let(:mapping) { described_class::ClassMapping.new }
    let(:registry) { described_class::NamespaceRegistry.new }
    let(:generator) { described_class::Generator.new(class_mapping: mapping, namespaces: registry) }

    let(:model) do
      fake_class = Struct.new(:name, :object_type, :object_id, :ea_guid)
      fake_attr = Struct.new(:name, :type, :object_id)

      Class.new do
        attr_reader :collections

        def initialize
          @collections = {
            objects: [],
            attributes: [],
            xrefs: []
          }
        end

        def add_class(name, type, attrs = [])
          id = collections[:objects].size + 1
          collections[:objects] << Struct.new(:name, :object_type, :object_id, :ea_guid).new(name, "Class", id, "{guid-#{id}}")
          attrs.each do |attr_name, attr_type|
            collections[:attributes] << Struct.new(:name, :type, :object_id).new(attr_name, attr_type, id)
          end
        end
      end.new.tap { |m| m.add_class("MyClass", "Class", [["name", "string"], ["count", "integer"]]) }
    end

    it "emits a valid XSD schema root element" do
      xsd = generator.call(model, target_namespace: "http://test")
      parsed = Nokogiri::XML(xsd)
      expect(parsed.root.name).to eq("schema")
      expect(parsed.root["targetNamespace"]).to eq("http://test")
    end

    it "emits element + complexType for each class" do
      xsd = generator.call(model, target_namespace: "http://test")
      parsed = Nokogiri::XML(xsd)
      parsed.xpath("//xs:element", "xs" => Ea::Export::Xsd::Generator::XSD_NS)
      # default element name is class name downcase
      expect(parsed.css("element").map { |n| n["name"] }).to include("myclass")
      expect(parsed.css("complexType").map { |n| n["name"] })
        .to include("MyClassType")
    end

    it "declares child elements for each attribute" do
      xsd = generator.call(model, target_namespace: "http://test")
      parsed = Nokogiri::XML(xsd)

      type_def = parsed.css("complexType[name='MyClassType']").first
      expect(type_def).not_to be_nil
      child_names = type_def.css("element").map { |n| n["name"] }
      expect(child_names).to include("name", "count")
    end

    it "uses ClassMapping when present" do
      mapping_with = described_class::ClassMapping.new(
        "MyClass" => described_class::ClassMapping::Mapping.new(
          name: "MyClass", element: "myElement", type: "MyType",
          property_type: nil, type_content: "complex"
        )
      )
      gen = described_class::Generator.new(class_mapping: mapping_with)
      xsd = gen.call(model, target_namespace: "http://test")
      parsed = Nokogiri::XML(xsd)

      expect(parsed.css("element").map { |n| n["name"] }).to include("myElement")
      expect(parsed.css("complexType").map { |n| n["name"] }).to include("MyType")
    end
  end
end
