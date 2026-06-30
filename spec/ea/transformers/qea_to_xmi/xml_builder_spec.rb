# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::XmlBuilder do
  let(:namespaces) do
    {
      "xmlns:xmi": Ea::Transformers::QeaToXmi::SparxNamespaces::XMI,
      "xmlns:uml": Ea::Transformers::QeaToXmi::SparxNamespaces::UML,
    }
  end

  def build_with(&block)
    described_class.new.root(namespaces) { |x| x.instance_exec(x, &block) }
  end

  describe "#root" do
    it "creates the xmi:XMI root with prefixed name" do
      b = described_class.new
      b.root(namespaces)
      parsed = Nokogiri::XML(b.to_xml)
      expect(parsed.root.name).to eq("XMI")
      expect(parsed.root.namespace.prefix).to eq("xmi")
    end

    it "declares the passed xmlns: prefixes" do
      b = described_class.new
      b.root(namespaces)
      ns = Nokogiri::XML(b.to_xml).root.namespaces
      expect(ns["xmlns:xmi"]).to eq(Ea::Transformers::QeaToXmi::SparxNamespaces::XMI)
      expect(ns["xmlns:uml"]).to eq(Ea::Transformers::QeaToXmi::SparxNamespaces::UML)
    end

    it "passes non-xmlns attributes through as regular attributes" do
      b = described_class.new
      b.root(namespaces.merge("xmi:version" => "2.5.1"))
      parsed = Nokogiri::XML(b.to_xml)
      expect(parsed.root["xmi:version"]).to eq("2.5.1")
    end
  end

  describe "prefixed element dispatch" do
    it "emits <xmi:Documentation> with the xmi prefix" do
      b = described_class.new
      b.root(namespaces) { |x| x.Documentation(exporter: "EA") }
      doc = Nokogiri::XML(b.to_xml).at_xpath("//xmi:Documentation")
      expect(doc).not_to be_nil
      expect(doc["exporter"]).to eq("EA")
    end

    it "emits <uml:Model> with the uml prefix" do
      b = described_class.new
      b.root(namespaces) { |x| x.Model(name: "EA_Model") }
      model = Nokogiri::XML(b.to_xml).at_xpath("//uml:Model")
      expect(model).not_to be_nil
      expect(model["name"]).to eq("EA_Model")
    end
  end

  describe "unprefixed element dispatch (the Sparx mixed-prefix style)" do
    it "emits <packagedElement> with no prefix even under <uml:Model>" do
      b = described_class.new
      b.root(namespaces) do |x|
        x.Model(name: "M") { x.packagedElement(name: "P") }
      end
      parsed = Nokogiri::XML(b.to_xml)
      packaged = parsed.at_xpath("//packagedElement")
      expect(packaged).not_to be_nil
      expect(packaged.namespace).to be_nil
    end

    it "does not prefix any descendant packagedElement" do
      b = described_class.new
      b.root(namespaces) do |x|
        x.Model do
          x.packagedElement do
            x.packagedElement
          end
        end
      end
      parsed = Nokogiri::XML(b.to_xml)
      expect(parsed.xpath("//uml:packagedElement").size).to eq(0)
      expect(parsed.xpath("//packagedElement").size).to eq(2)
    end

    it "supports arbitrary tag names via method dispatch" do
      b = described_class.new
      b.root(namespaces) do |x|
        x.fooBar("xmi:type": "uml:Foo")
      end
      parsed = Nokogiri::XML(b.to_xml)
      expect(parsed.at_xpath("//fooBar")).not_to be_nil
    end
  end

  describe "block-based nesting" do
    it "nests children inside the parent block" do
      b = described_class.new
      b.root(namespaces) do |x|
        x.Model do
          x.ownedAttribute(name: "attr1")
        end
      end
      parsed = Nokogiri::XML(b.to_xml)
      attr = parsed.at_xpath("//ownedAttribute")
      expect(attr).not_to be_nil
      expect(attr["name"]).to eq("attr1")
    end

    it "restores parent context after block exits" do
      b = described_class.new
      b.root(namespaces) do |x|
        x.Model do
          x.ownedAttribute
        end
        x.Documentation # should be child of XMI root, not Model
      end
      parsed = Nokogiri::XML(b.to_xml)
      docs_parent = parsed.at_xpath("//xmi:Documentation").parent
      expect(docs_parent.name).to eq("XMI")
    end
  end

  describe "#to_xml" do
    it "returns a valid XML declaration" do
      b = described_class.new
      b.root(namespaces)
      xml = b.to_xml
      expect(xml).to match(/\A<\?xml version="1.0" encoding="UTF-8"\?>/)
    end

    it "parses without errors" do
      b = described_class.new
      b.root(namespaces) { |x| x.Documentation }
      expect(Nokogiri::XML(b.to_xml).errors).to be_empty
    end
  end
end
