# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::Transformer do
  let(:qea_path) { fixtures_path("basic.qea") }
  let(:database) { Ea::Qea.load(qea_path) }
  let(:xml) { described_class.new(database).serialize(with_extensions: false) }
  let(:parsed) { Nokogiri::XML(xml) }

  after { database.close_connection }

  def count_xmi_type(type)
    parsed.xpath(%(//*[@xmi:type="#{type}"])).size
  end

  describe "document framing" do
    it "emits an xmi:XMI root with EA's Sparx namespace declarations" do
      root = parsed.root
      expect(root.name).to eq("XMI")
      expect(root.namespace.prefix).to eq("xmi")
      # EA uses the 2011-07-01 XMI/UML namespace URIs (not 2013-10-01).
      expect(root.namespaces["xmlns:xmi"]).to eq("http://www.omg.org/spec/XMI/20110701")
      expect(root.namespaces["xmlns:uml"]).to eq("http://www.omg.org/spec/UML/20110701")
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

    it "emits one Class node per Class t_object" do
      # Counts every uml:Class node — packaged AND nested (EA nests
      # child classes as nestedClassifier).
      expected = database.objects.count { |o| o.object_type == "Class" }
      expect(count_xmi_type("uml:Class")).to eq(expected)
    end

    it "nests child classes as nestedClassifier (EA convention)" do
      # basic.qea: 35 Class rows have a nonzero parentid; EA's reference
      # packages the other 30 and nests these 35.
      expect(parsed.xpath(%(//packagedElement[@xmi:type="uml:Class"])).size).to eq(30)
      expect(parsed.xpath(%(//nestedClassifier[@xmi:type="uml:Class"])).size).to eq(35)
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
    # Only UmlModel and PackagedElement own packaged_element children — check
    # explicitly via is_a? rather than respond_to? so the contract stays
    # visible in the spec.
    def count_xmi_type_recursive(model, type)
      count = model.is_a?(::Xmi::Uml::PackagedElement) && model.type == type ? 1 : 0
      children = if model.is_a?(::Xmi::Uml::PackagedElement)
                   model.packaged_element + model.nested_classifier
                 elsif model.is_a?(::Xmi::Uml::UmlModel)
                   model.packaged_element
                 else
                   []
                 end
      count + children.sum { |child| count_xmi_type_recursive(child, type) }
    end

    it "preserves class count from the database" do
      # Filter matches EaObject#transformer_type: Class and Interface
      # rows map to :class; Enumeration-stereotype Class rows map to
      # :enumeration and are not counted here.
      expected = database.objects.count { |o| o.transformer_type == :class }
      actual = count_xmi_type_recursive(reparsed.model, "uml:Class")
      expect(actual).to eq(expected)
    end

    it "preserves enumeration count from the database" do
      expected = database.objects.count { |o| o.transformer_type == :enumeration }
      actual = count_xmi_type_recursive(reparsed.model, "uml:Enumeration")
      expect(actual).to eq(expected)
    end

    it "preserves data_type count from the database" do
      expected = database.objects.count { |o| o.transformer_type == :data_type }
      actual = count_xmi_type_recursive(reparsed.model, "uml:DataType") +
               count_xmi_type_recursive(reparsed.model, "uml:PrimitiveType")
      expect(actual).to eq(expected)
    end

    it "preserves instance count from the database" do
      expected = database.objects.count { |o| o.transformer_type == :instance }
      actual = count_xmi_type_recursive(reparsed.model, "uml:InstanceSpecification")
      expect(actual).to eq(expected)
    end
  end

  describe "Phase 2 wiring (xmi gem schema migration landed)" do
    # These specs assert that the attributes the xmi gem now models
    # are present in the output. The schema migration in the xmi gem
    # (refactor/owned-end-schema-gap) closed TODO.next/26 fully and
    # wired up the Phase 2 attribute gaps from TODO.next/21 §2.

    it "omits visibility on Property when public (UML default, matches EA)" do
      # EA omits visibility="public" — only non-public visibility is emitted.
      expect(parsed.xpath("//ownedAttribute[@visibility='public']")).to be_empty
    end

    it "emits visibility=private for Private-scoped attributes" do
      # Every t_attribute row in basic.qea has Scope="Private"; EA's
      # reference marks all 102 as visibility="private".
      expect(parsed.xpath("//ownedAttribute[@visibility='private']").size).to eq(102)
    end

    it "emits visibility on Operation only when non-public" do
      ops_without_vis = parsed.xpath("//ownedOperation[not(@visibility)]")
      expect(ops_without_vis).not_to be_empty
    end

    it "omits isAbstract when false (UML default, matches EA)" do
      elements_without_abs = parsed.xpath("//packagedElement[not(@isAbstract)]")
      expect(elements_without_abs).not_to be_empty
    end

    it "emits upperValue/lowerValue on ownedEnd (TODO 26 closed)" do
      expect(parsed.xpath("//ownedEnd/upperValue")).not_to be_empty
      expect(parsed.xpath("//ownedEnd/lowerValue")).not_to be_empty
    end

    it "emits slots on InstanceSpecification from t_object.runstate (TODO 35 closed)" do
      # 22 slots in basic.qea — one per RunState @VAR block across the
      # fixture's instance specifications.
      expect(parsed.xpath("//slot").size).to eq(22)
    end

    it "emits each slot body with the RunState operator prepended verbatim" do
      # Exact body set copied from examples/exports/basic/model.xml —
      # including the one <= operator EA emits verbatim. (The previous
      # form of this example matched @type instead of @xmi:type and
      # passed vacuously over an empty node set.)
      bodies = parsed.xpath("//slot/value[@xmi:type='uml:OpaqueExpression']/@body").map(&:value)
      expect(bodies.tally).to eq(
        "=Value One" => 5, "=valueOne" => 5, "=valueTwo" => 4,
        "=valueThree" => 4, "=Value Two" => 3, "<=valueTwo" => 1
      )
    end

    it "emits definingFeature on slots whose instance has a classifier" do
      # InstanceSpecifications with pdata1 set resolve to a classifier
      # attribute; slots without a classifier omit definingFeature.
      with_df = parsed.xpath("//slot[@definingFeature]")
      expect(with_df).not_to be_empty
    end

    it "synthesises EAID_SL and EAID_OE prefixes per Sparx convention" do
      expect(xml).to include("EAID_SL")
      expect(xml).to include("EAID_OE")
    end
  end

  describe "Phase 2 gaps still deferred (see TODO.next/21 §2)" do
    # These gaps remain because the basic.qea fixture doesn't carry
    # data that exercises them. The xmi gem now models the attributes;
    # wiring on the ea side will flip these to positive assertions
    # when a fixture with relevant data is available, or when the
    # InstanceSpecification pdata1 / connector containment fields are
    # walked explicitly.

    it "emits classifier on InstanceSpecification (from t_object.classifier)" do
      expect(parsed.xpath("//packagedElement[@classifier]")).not_to be_empty
    end

    it "emits aggregation on ownedEnd when EA indicates composite/shared" do
      # basic.qea has aggregation/composition connectors — the
      # aggregation attribute should be emitted from the
      # sourceisaggregate/destisaggregate fields.
      expect(parsed.xpath("//ownedEnd[@aggregation]")).not_to be_empty
    end
  end

  describe "API stability" do
    it "exposes a stateless serialize method" do
      t1 = described_class.new(database)
      t2 = described_class.new(database)
      expect(t1.serialize(with_extensions: false)).to eq(t2.serialize(with_extensions: false))
    end

    it "does not mutate the database during serialization" do
      expect { described_class.new(database).serialize(with_extensions: false) }.not_to change {
        [database.packages.size, database.objects.size, database.connectors.size]
      }
    end
  end

  describe "synthesized ID parity with EA" do
    # Literal IDs copied from examples/exports/basic/model.xml. These
    # protect the transformer call sites: owner, prefix, and allocation
    # order (lower before upper, destination end before source end,
    # global LI counter in document walk order).
    it "gives the first association's ends the LI000001-4 ladder" do
      (1..4).each do |n|
        expect(xml).to include(%(xmi:id="EAID_LI00000#{n}__EEB1_4de7_98F5_670D6EE4A52B"))
      end
    end

    it "derives attribute LI tails from the attribute's own GUID" do
      expect(xml).to include(%(xmi:id="EAID_LI000009_CA01_4c63_8311_0EC8F355E932"))
    end

    it "numbers slots and values from zero per instance" do
      expect(xml).to include(%(xmi:id="EAID_SL000000_9F66_4e33_8E49_469BD346DAA1"))
      expect(xml).to include(%(xmi:id="EAID_OE000000_9F66_4e33_8E49_469BD346DAA1"))
    end

    it "numbers every return parameter RT000000 scoped to its operation" do
      expect(xml).to include(%(xmi:id="EAID_RT000000_3EE1_4598_9615_F2068D192111"))
    end
  end

  describe "classifier type resolution" do
    it "resolves integer classifiers to the object's xmi id, never EAID_0" do
      test_db = Ea::Qea.load("examples/qea/test.qea")
      begin
        test_xml = Ea::Transformers.qea_to_xmi(test_db)
        expect(test_xml).not_to include(%(idref="EAID_0"))
      ensure
        test_db.close_connection
      end
    end

    it "emits PrimitiveType objects (simple.qea AcmeUmlPrimitive)" do
      simple_db = Ea::Qea.load("examples/qea/simple.qea")
      begin
        simple_xml = Ea::Transformers.qea_to_xmi(simple_db)
        expect(simple_xml).to include(%(xmi:type="uml:PrimitiveType"))
        expect(simple_xml).to include("AcmeUmlPrimitive")
      ensure
        simple_db.close_connection
      end
    end
  end

  describe "package dependencies" do
    # Literal values from examples/exports/basic/model.xml: dependencies
    # between Package objects resolve endpoints to EAPK_ package refs
    # via the object's PDATA1 → t_package link.
    it "emits the three package-level uml:Dependency elements" do
      deps = parsed.xpath(%(//packagedElement[@xmi:type="uml:Dependency"]))
      expect(deps.size).to eq(3)
      dep = deps.find { |d| d["xmi:id"] == "EAID_3DC3F2A8_5EA3_4feb_B6D3_397DA58BBEA3" }
      expect(dep["client"]).to eq("EAPK_F5BFAAC7_BB6F_4f69_8C78_3775A0C86CDB")
      expect(dep["supplier"]).to eq("EAPK_45D98ADF_46E0_4bf6_B94F_8E504ABD1AB7")
    end
  end

  describe "signals and primitive type references" do
    # Literal expectations copied from examples/exports/basic/model.xml.
    it "emits the three Signal objects as uml:Signal packagedElements" do
      expect(parsed.xpath(%(//packagedElement[@xmi:type="uml:Signal"])).size).to eq(3)
      expect(xml).to include(%(xmi:id="EAID_A53E4556_FAEE_458d_B9B2_93B41FA424AC"))
    end

    it "references int-typed attributes via the OMG PrimitiveTypes href" do
      hrefs = parsed.xpath(%(//ownedAttribute/type[@href]))
      expect(hrefs.size).to eq(90)
      expect(hrefs.first["href"])
        .to eq("http://www.omg.org/spec/UML/20110701/PrimitiveTypes.xmi#Integer")
    end

    it "types return parameters with their EAnone reference" do
      returns = parsed.xpath(%(//ownedParameter[@direction="return"]))
      expect(returns.size).to eq(12)
      expect(returns.map { |p| p["type"] }.uniq).to eq(["EAnone_void"])
    end
  end

  describe "interface realizations" do
    let(:package) do
      Ea::Qea::Models::EaPackage.new(
        package_id: 1, name: "P", parent_id: 0,
        ea_guid: "{AAAAAAAA-1111-2222-3333-444444444444}"
      )
    end

    let(:client_class) do
      Ea::Qea::Models::EaObject.new(
        ea_object_id: 10, object_type: "Class", name: "C", package_id: 1,
        ea_guid: "{BBBBBBBB-1111-2222-3333-444444444444}"
      )
    end

    let(:supplier_interface) do
      Ea::Qea::Models::EaObject.new(
        ea_object_id: 11, object_type: "Interface", name: "I", package_id: 1,
        ea_guid: "{CCCCCCCC-1111-2222-3333-444444444444}"
      )
    end

    def realization_database(connector_type:, end_object_id: 11)
      connector = Ea::Qea::Models::EaConnector.new(
        connector_id: 5, connector_type: connector_type,
        start_object_id: 10, end_object_id: end_object_id,
        ea_guid: "{DDDDDDDD-1111-2222-3333-444444444444}"
      )
      build_test_database(
        packages: [package],
        objects: [client_class, supplier_interface],
        connectors: [connector]
      )
    end

    it "serializes a Realization connector as interfaceRealization" do
      db = realization_database(connector_type: "Realization")
      xml = described_class.new(db).serialize(with_extensions: false)
      expect(xml).to include("<interfaceRealization")
    end

    it "serializes the UK-spelled Realisation the same way" do
      db = realization_database(connector_type: "Realisation")
      xml = described_class.new(db).serialize(with_extensions: false)
      expect(xml).to include("<interfaceRealization")
    end

    it "skips the realization when the supplier object is missing" do
      db = realization_database(connector_type: "Realization", end_object_id: 999)
      xml = described_class.new(db).serialize(with_extensions: false)
      expect(xml).not_to include("<interfaceRealization")
    end
  end
end
