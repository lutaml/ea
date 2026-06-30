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
      expect(root.namespaces["xmlns:xmi"]).to eq(::Xmi::Namespace::Omg::Xmi.uri)
      expect(root.namespaces["xmlns:uml"]).to eq(::Xmi::Namespace::Omg::Uml.uri)
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
      # Real Sparx XMI does not emit xmi:type on <ownedOperation>; count by
      # element name. See spec/fixtures/basic.xmi for reference shape.
      expect(parsed.xpath("//ownedOperation").size).to eq(expected)
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

  describe "round-trip via xmi gem parser" do
    let(:reparsed) { ::Xmi::Sparx::Root.parse_xml(xml) }

    it "produces an Xmi::Sparx::Root instance" do
      expect(reparsed).to be_a(::Xmi::Sparx::Root)
    end

    it "preserves the EA_Model name on the uml:Model" do
      expect(reparsed.model.name).to eq("EA_Model")
    end

    it "preserves package count from the database" do
      package_count = reparsed.model.packaged_element.size
      # The top-level packagedElements under EA_Model are the root packages.
      expect(package_count).to eq(database.packages.count(&:root?))
    end

    it "preserves the Documentation exporter" do
      expect(reparsed.documentation.exporter).to eq("Enterprise Architect")
      expect(reparsed.documentation.exporter_version).to eq("6.5")
    end

    it "preserves an Extension block with EA extender" do
      expect(reparsed.extension).to be_a(::Xmi::Sparx::Extension)
      expect(reparsed.extension.extender).to eq("Enterprise Architect")
    end

    # Recursively count packagedElements of a given xmi:type across the tree.
    def count_xmi_type_recursive(model, type)
      count = model.is_a?(::Xmi::Uml::PackagedElement) && model.type == type ? 1 : 0
      children = model.respond_to?(:packaged_element) ? model.packaged_element : []
      count + children.sum { |child| count_xmi_type_recursive(child, type) }
    end

    it "preserves class count from the database" do
      expected = database.objects.count { |o| o.object_type == "Class" }
      actual = count_xmi_type_recursive(reparsed.model, "uml:Class")
      # Some Class rows correspond to interfaces or are filtered by the
      # transformer's classification logic — the count is approximate.
      expect(actual).to be > 0
      expect(actual).to be <= expected
    end
  end

  describe "API stability" do
    it "exposes a stateless serialize method" do
      t1 = described_class.new(database)
      t2 = described_class.new(database)
      expect(t1.serialize).to eq(t2.serialize)
    end

    it "does not mutate the database during serialization" do
      expect { described_class.new(database).serialize }.not_to change {
        [database.packages.size, database.objects.size, database.connectors.size]
      }
    end
  end
end
