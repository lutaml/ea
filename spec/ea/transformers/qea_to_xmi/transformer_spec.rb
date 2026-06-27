# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::Transformer do
  let(:qea_path) { fixtures_path("basic.qea") }
  let(:database) { Ea::Qea.load(qea_path) }
  let(:xml) { described_class.new(database).serialize }
  let(:parsed) { Nokogiri::XML(xml) }

  after { database.close_connection }

  def count_xmi_type(type)
    parsed.xpath(%(//*[@xmi:type="#{type}"])).size
  end

  describe "document framing" do
    it "emits an xmi:XMI root with the Sparx namespace declarations" do
      root = parsed.root
      expect(root.name).to eq("XMI")
      expect(root.namespace.prefix).to eq("xmi")
      expect(root.namespaces["xmlns:xmi"]).to eq(Ea::Transformers::QeaToXmi::SparxNamespaces::XMI)
      expect(root.namespaces["xmlns:uml"]).to eq(Ea::Transformers::QeaToXmi::SparxNamespaces::UML)
    end

    it "includes the xmi:Documentation block with EA exporter info" do
      doc_node = parsed.at_xpath("//xmi:Documentation")
      expect(doc_node).not_to be_nil
      expect(doc_node["exporter"]).to eq("Enterprise Architect")
      expect(doc_node["exporterVersion"]).to eq("6.5")
    end

    it "emits exactly one uml:Model named EA_Model" do
      models = parsed.xpath("//uml:Model")
      expect(models.size).to eq(1)
      expect(models.first["name"]).to eq("EA_Model")
    end
  end

  describe "mixed-prefix style" do
    it "keeps children of uml:Model unprefixed (Sparx convention)" do
      model = parsed.at_xpath("//uml:Model")
      packaged = model.children.find { |n| n.element? && n.name == "packagedElement" }
      expect(packaged).not_to be_nil
      expect(packaged.namespace).to be_nil
    end

    it "keeps descendant packagedElement nodes unprefixed at all depths" do
      prefixed = parsed.xpath("//uml:packagedElement")
      expect(prefixed.size).to eq(0)
    end
  end

  describe "count parity (QEA tables → XML elements)" do
    it "emits one Package packagedElement per t_package row" do
      expected = database.packages.size
      expect(count_xmi_type("uml:Package")).to eq(expected)
    end

    it "emits one Class packagedElement per Class t_object" do
      expected = database.objects.count { |o| o.object_type == "Class" }
      expect(count_xmi_type("uml:Class")).to eq(expected)
    end

    it "emits one Enumeration per Enumeration t_object" do
      expected = database.objects.count { |o| o.object_type == "Enumeration" }
      expect(count_xmi_type("uml:Enumeration")).to eq(expected)
    end

    it "emits one InstanceSpecification per Object t_object" do
      expected = database.objects.count { |o| o.object_type == "Object" }
      expect(count_xmi_type("uml:InstanceSpecification")).to eq(expected)
    end

    it "emits one Property per t_attribute row plus one per association end" do
      attributes_count = database.objects.sum do |obj|
        database.attributes_for_object(obj.ea_object_id).size
      end
      assoc_types = %w[Association Aggregation Composition]
      association_end_count = database.connectors.count do |c|
        assoc_types.include?(c.connector_type)
      end * 2
      expected = attributes_count + association_end_count
      expect(count_xmi_type("uml:Property")).to eq(expected)
    end

    it "emits one Operation per t_operation row" do
      expected = database.objects.sum do |obj|
        database.operations_for_object(obj.ea_object_id).size
      end
      expect(count_xmi_type("uml:Operation")).to eq(expected)
    end

    it "emits one Association per Association/Aggregation/Composition connector" do
      assoc_types = %w[Association Aggregation Composition]
      expected = database.connectors.count do |c|
        assoc_types.include?(c.connector_type)
      end
      expect(count_xmi_type("uml:Association")).to eq(expected)
    end

    it "emits one Generalization per Generalization connector" do
      expected = database.connectors.count { |c| c.connector_type == "Generalization" }
      expect(parsed.xpath("//generalization").size).to eq(expected)
    end
  end

  describe "GUID preservation" do
    it "emits EAPK_ identifiers for all packages" do
      database.packages.each do |pkg|
        next unless pkg.ea_guid
        expected = Ea::Transformers::QeaToXmi::GuidFormat.ea_guid_to_xmi_id(
          pkg.ea_guid, prefix: "EAPK",
        )
        expect(xml).to include(%(xmi:id="#{expected}"))
      end
    end

    it "emits EAID_ identifiers for all classifier objects" do
      database.objects.each do |obj|
        next unless obj.ea_guid
        next unless obj.object_type == "Class"
        expected = Ea::Transformers::QeaToXmi::GuidFormat.ea_guid_to_xmi_id(obj.ea_guid)
        expect(xml).to include(%(xmi:id="#{expected}"))
      end
    end
  end

  describe "well-formedness" do
    it "parses without XML errors" do
      expect(parsed.errors).to be_empty
    end

    it "is parseable by the xmi gem's Sparx parser" do
      require "xmi"
      expect { ::Xmi::Sparx::Root.parse_xml(xml) }.not_to raise_error
    end
  end
end
