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

  describe "classifier dispatch registry" do
    # The capabilities map is read with a default, so an unclassified
    # kind loses its bounds or its nested children silently — wrong XML,
    # no exception. This assertion is the only exhaustiveness check that
    # exists, and it has to fail in both directions: a builder with no
    # capabilities entry, and an entry with no builder.
    it "classifies exactly the kinds the builder registry can build" do
      expect(described_class::CLASSIFIER_CAPABILITIES.keys)
        .to match_array(described_class::CLASSIFIER_BUILDERS.keys)
    end
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

  describe "return parameter type spelling" do
    # EA writes the classifier reference unprefixed. The xmi gem keeps
    # that slot namespaced for the XMI metaclass discriminator, which is
    # correct for general UML XMI, so the exporter restores EA's form
    # here rather than in the shared model.
    #
    # Nokogiri keys attributes by local name, so the parity ratchet
    # cannot see this difference — only a raw string check can.
    it "writes an unprefixed type, like EA" do
      # Anchored on the space: `xmi:type="EAnone_void"` contains the
      # unprefixed spelling as a substring, so a plain include passes
      # either way.
      expect(xml).to match(/<ownedParameter\b[^>]*\stype="EAnone_void"/)
    end

    it "leaves no xmi:type on any ownedParameter" do
      expect(xml.scan(/<ownedParameter\b[^>]*xmi:type=/)).to be_empty
    end

    it "matches EA's reference count of unprefixed parameter types" do
      # The reference carries bytes that are not valid UTF-8; scrub so
      # String#scan does not raise on them.
      reference = File.read("examples/exports/basic/model.xml").scrub
      expected = reference.scan(/<ownedParameter\b[^>]*\stype="/).size
      expect(xml.scan(/<ownedParameter\b[^>]*\stype="/).size).to eq(expected)
    end

    it "skips the return parameter when the operation has no usable guid" do
      # EA derives the RT id's tail from the operation's GUID, so an
      # operation without one produced a tailless `xmi:id="EAID_RT000000"`
      # in the UML tree while the extension block emitted nothing —
      # the two describing different operations.
      package = Ea::Qea::Models::EaPackage.new(
        package_id: 1, name: "P", parent_id: 0,
        ea_guid: "{AAAAAAAA-1111-2222-3333-444444444444}"
      )
      owner = synthetic_object(10, type: "Class", name: "C")
      operation = Ea::Qea::Models::EaOperation.new(
        operationid: 3, ea_object_id: 10, name: "m", type: "int",
        pos: 0, ea_guid: nil
      )
      database = build_test_database(packages: [package], objects: [owner],
                                     operations: [operation])
      output = described_class.new(database).serialize
      expect(output.scan(/direction="return"/).size)
        .to eq(output.scan(/EAID_RETURNID_/).size)
      expect(output).not_to include(%(xmi:id="EAID_RT000000"))
    end

    it "leaves a parameter name containing the literal xmi:type= alone" do
      # Parameter names are free text out of EA. Substituting on the raw
      # tag would rewrite this one inside its quotes.
      package = Ea::Qea::Models::EaPackage.new(
        package_id: 1, name: "P", parent_id: 0,
        ea_guid: "{AAAAAAAA-1111-2222-3333-444444444444}"
      )
      owner = synthetic_object(10, type: "Class", name: "C")
      operation = Ea::Qea::Models::EaOperation.new(
        operationid: 3, ea_object_id: 10, name: "m", type: "int",
        pos: 0, ea_guid: "{CCCCCCCC-1111-2222-3333-444444444444}"
      )
      param = Ea::Qea::Models::EaOperationParam.new(
        operationid: 3, name: %(literal xmi:type= marker), type: "int", pos: 1,
        ea_guid: "{DDDDDDDD-1111-2222-3333-444444444444}"
      )
      database = build_test_database(packages: [package], objects: [owner],
                                     operations: [operation], operation_params: [param])
      output = described_class.new(database).serialize(with_extensions: false)
      expect(output).to include(%(name="literal xmi:type= marker"))
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

  # Synthetic-model builders for the specs below.
  def synthetic_package
    Ea::Qea::Models::EaPackage.new(
      package_id: 1, name: "P", parent_id: 0,
      ea_guid: "{AAAAAAAA-1111-2222-3333-444444444444}"
    )
  end

  def synthetic_object(id, type:, name:, parentid: 0)
    Ea::Qea::Models::EaObject.new(
      ea_object_id: id, object_type: type, name: name, package_id: 1,
      parentid: parentid, ea_guid: "{#{format("%08d", id)}-1111-2222-3333-444444444444}"
    )
  end

  describe "Association t_object rows" do
    # simple.qea carries AcmeUmlAssociation as a t_object row, not a
    # connector. EA exports it bare — see examples/exports/simple/
    # model.xml:13.
    let(:simple_doc) do
      simple_db = Ea::Qea.load("examples/qea/simple.qea")
      begin
        Nokogiri::XML(Ea::Transformers.qea_to_xmi(simple_db))
      ensure
        simple_db.close_connection
      end
    end

    let(:association_id) { "EAID_D1D68870_3A7C_4ce3_9F1A_BB7FF5D99E17" }

    it "emits the association as a bare uml:Association packagedElement" do
      node = simple_doc.at_xpath(%(//packagedElement[@xmi:id="#{association_id}"]))
      expect(node["xmi:type"]).to eq("uml:Association")
      expect(node["name"]).to eq("AcmeUmlAssociation")
      expect(node.element_children).to be_empty
    end

    it "types its extension element as uml:Association" do
      node = simple_doc.at_xpath(%(//element[@xmi:idref="#{association_id}"]))
      expect(node["xmi:type"]).to eq("uml:Association")
    end
  end

  describe "operation return types with a blank classifier" do
    let(:operation) do
      Ea::Qea::Models::EaOperation.new(
        operationid: 3, ea_object_id: 10, name: "count", type: "int",
        classifier: "", pos: 0, ea_guid: "{CCCCCCCC-1111-2222-3333-444444444444}"
      )
    end

    let(:xml) do
      database = build_test_database(packages: [synthetic_package], operations: [operation],
                                     objects: [synthetic_object(10, type: "Class", name: "C")])
      described_class.new(database).serialize
    end

    it "defines the EAnone_ primitive its return parameter references" do
      expect(xml).to include(%(type="EAnone_int"))
      expect(xml).to include(%(xmi:id="EAnone_int"))
    end

    it "leaves no EAnone_ reference undefined" do
      referenced = xml.scan(/(?:type|idref)="(EAnone_[^"]*)"/).flatten.uniq
      defined = xml.scan(/xmi:id="(EAnone_[^"]*)"/).flatten.uniq
      expect(referenced - defined).to be_empty
    end
  end

  describe "type names EA stores with surrounding whitespace" do
    # t_operation.Type is free text. The reference and the
    # <primitivetypes> definition used to normalize it differently, so
    # the idref pointed at an id nobody defined.
    let(:xml) do
      operation = Ea::Qea::Models::EaOperation.new(
        operationid: 3, ea_object_id: 10, name: "count", type: "  int  ",
        classifier: "", pos: 0, ea_guid: "{CCCCCCCC-1111-2222-3333-444444444444}"
      )
      database = build_test_database(packages: [synthetic_package], operations: [operation],
                                     objects: [synthetic_object(10, type: "Class", name: "C")])
      described_class.new(database).serialize
    end

    it "references and defines the same stripped id" do
      expect(xml).to include(%(type="EAnone_int"))
      expect(xml).to include(%(xmi:id="EAnone_int"))
    end

    it "leaves no EAnone_ reference undefined" do
      referenced = xml.scan(/(?:type|idref)="(EAnone_[^"]*)"/).flatten.uniq
      defined = xml.scan(/xmi:id="(EAnone_[^"]*)"/).flatten.uniq
      expect(referenced - defined).to be_empty
    end
  end

  describe "a classifier id that resolves to nothing" do
    # KNOWN GAP. The reference falls back to EAnone_int, but the
    # definition side only defines names whose classifier is blank, so
    # the idref dangles. Defining it from here instead over-emits:
    # PrimitiveTypes scans every row in the database, including rows the
    # walk never exports, and EA's own plateau export defines nothing
    # for them. See lib/ea/transformers/qea_to_xmi/primitive_types.rb.
    let(:xml) do
      operation = Ea::Qea::Models::EaOperation.new(
        operationid: 3, ea_object_id: 10, name: "count", type: "int",
        classifier: "999", pos: 0, ea_guid: "{CCCCCCCC-1111-2222-3333-444444444444}"
      )
      database = build_test_database(packages: [synthetic_package], operations: [operation],
                                     objects: [synthetic_object(10, type: "Class", name: "C")])
      described_class.new(database).serialize
    end

    it "leaves no EAnone_ reference undefined" do
      pending "definitions follow a whole-database scan, not the emitted references"
      referenced = xml.scan(/(?:type|idref)="(EAnone_[^"]*)"/).flatten.uniq
      defined = xml.scan(/xmi:id="(EAnone_[^"]*)"/).flatten.uniq
      expect(referenced - defined).to be_empty
    end
  end

  describe "attribute types EA maps to the OMG PrimitiveTypes library" do
    # The href child replaces the idref only when there is no classifier
    # to point at. A resolvable classifier wins over the href name.
    def attribute_with(classifier)
      Ea::Qea::Models::EaAttribute.new(
        id: 5, ea_object_id: 10, name: "count", type: "int", pos: 0,
        classifier: classifier, ea_guid: "{DDDDDDDD-1111-2222-3333-444444444444}"
      )
    end

    def xml_for(classifier)
      attribute = attribute_with(classifier)
      database = build_test_database(
        packages: [synthetic_package], attributes: [attribute],
        objects: [synthetic_object(10, type: "Class", name: "C"),
                  synthetic_object(11, type: "DataType", name: "Int")]
      )
      described_class.new(database).serialize
    end

    it "emits the OMG href when the classifier is blank" do
      expect(xml_for("")).to include("PrimitiveTypes.xmi#Integer")
    end

    it "points at the classifier instead when it resolves" do
      xml = xml_for("11")
      expect(xml).to include(%(xmi:idref="EAID_00000011_1111_2222_3333_444444444444"))
      expect(xml).not_to include("PrimitiveTypes.xmi#Integer")
    end
  end

  describe "objects whose parent never nests them" do
    let(:objects) do
      [synthetic_object(20, type: "Enumeration", name: "E"),
       synthetic_object(21, type: "Class", name: "UnderEnum", parentid: 20),
       synthetic_object(30, type: "Class", name: "UnderMissing", parentid: 999),
       synthetic_object(40, type: "Class", name: "Parent"),
       synthetic_object(41, type: "Class", name: "UnderClass", parentid: 40)]
    end

    let(:parsed) do
      database = build_test_database(packages: [synthetic_package], objects: objects)
      Nokogiri::XML(described_class.new(database).serialize(with_extensions: false))
    end

    def names_at(xpath)
      parsed.xpath(xpath).map { |node| node["name"] }
    end

    it "keeps children their parent never nests at package level" do
      expect(names_at("//packagedElement/packagedElement")).to include("UnderEnum", "UnderMissing")
    end

    it "still nests a child of a class" do
      expect(names_at("//packagedElement/packagedElement")).not_to include("UnderClass")
      expect(names_at("//nestedClassifier")).to eq(["UnderClass"])
    end
  end

  describe "a grandchild under an orphaned parent" do
    # The orphan sorts AFTER its own child here, so a walk that decides
    # orphan-hood from what it has emitted so far would snapshot the
    # grandchild as un-nested and emit it a second time on the same
    # xmi:id. Adoption is structural, so it is emitted exactly once.
    let(:objects) do
      [synthetic_object(20, type: "Enumeration", name: "E"),
       synthetic_object(21, type: "Class", name: "OrphanUnderEnum", parentid: 20),
       synthetic_object(22, type: "Class", name: "GrandchildUnderOrphan", parentid: 21)]
    end

    let(:nodes) do
      database = build_test_database(packages: [synthetic_package], objects: objects)
      parsed = Nokogiri::XML(described_class.new(database).serialize(with_extensions: false))
      parsed.xpath(%(//*[@name="GrandchildUnderOrphan"]))
    end

    it "emits the grandchild exactly once" do
      expect(nodes.size).to eq(1)
    end

    it "emits it as a nestedClassifier of the orphan" do
      expect(nodes.first.name).to eq("nestedClassifier")
      expect(nodes.first.parent["name"]).to eq("OrphanUnderEnum")
    end
  end

  describe "a ParentID chain that never terminates" do
    # A corrupt model can point an object at itself or round a cycle.
    # Both ends are nesting kinds, so treating them as adopted would
    # leave every one of them waiting on a parent that is never built —
    # they would vanish from the export without a word.
    def emitted_names(objects)
      database = build_test_database(packages: [synthetic_package], objects: objects)
      parsed = Nokogiri::XML(described_class.new(database).serialize(with_extensions: false))
      objects.to_h { |obj| [obj.name, parsed.xpath(%(//*[@name="#{obj.name}"])).size] }
    end

    it "still emits an object that is its own parent" do
      expect(emitted_names([synthetic_object(30, type: "Class", name: "Self", parentid: 30)]))
        .to eq("Self" => 1)
    end

    it "still emits both halves of a two-object cycle" do
      objects = [synthetic_object(40, type: "Class", name: "A", parentid: 41),
                 synthetic_object(41, type: "Class", name: "B", parentid: 40)]
      expect(emitted_names(objects)).to eq("A" => 1, "B" => 1)
    end
  end

  describe "serializing the same transformer twice" do
    it "returns identical XML both times" do
      database = build_test_database(
        packages: [synthetic_package],
        objects: [synthetic_object(20, type: "Enumeration", name: "E"),
                  synthetic_object(21, type: "Class", name: "UnderEnum", parentid: 20)]
      )
      transformer = described_class.new(database)
      first = transformer.serialize
      expect(transformer.serialize).to eq(first)
    end
  end

  describe "attribute bounds with only one EA column set" do
    # The explicit 1..1 is a property of the PAIR — EA applies it when
    # both t_attribute columns are blank. Defaulting each column on its
    # own would render the invalid 2..1 here.
    def bounds_for(lowerbound:, upperbound:)
      attribute = Ea::Qea::Models::EaAttribute.new(
        id: 5, ea_object_id: 10, name: "a", type: "int",
        lowerbound: lowerbound, upperbound: upperbound,
        ea_guid: "{DDDDDDDD-1111-2222-3333-444444444444}"
      )
      database = build_test_database(packages: [synthetic_package], attributes: [attribute],
                                     objects: [synthetic_object(10, type: "Class", name: "C")])
      node = Nokogiri::XML(described_class.new(database).serialize(with_extensions: false))
                     .at_xpath("//ownedAttribute")
      [node.at_xpath("lowerValue")["value"], node.at_xpath("upperValue")["value"]]
    end

    it "keeps a set lower bound and falls back to * for a blank upper" do
      expect(bounds_for(lowerbound: "2", upperbound: nil)).to eq(["2", "*"])
    end

    it "falls back to 0 for a blank lower and keeps a set upper" do
      expect(bounds_for(lowerbound: nil, upperbound: "5")).to eq(%w[0 5])
    end

    it "still writes EA's explicit 1..1 when both columns are blank" do
      expect(bounds_for(lowerbound: nil, upperbound: nil)).to eq(%w[1 1])
    end
  end

  describe "attribute bounds with no EA multiplicity" do
    # examples/exports/test/model.xml:183-187 — EA writes an explicit
    # 1..1 for a Property whose t_attribute bounds are NULL.
    it "emits 1..1 with the reference LI ids for test.qea Union.option1" do
      test_db = Ea::Qea.load("examples/qea/test.qea")
      begin
        doc = Nokogiri::XML(Ea::Transformers.qea_to_xmi(test_db))
        attr_node = doc.at_xpath(%(//ownedAttribute[@xmi:id="EAID_CDDC5C85_CD8A_48b4_BECD_FBFFBEAC015C"]))
        lower = attr_node.at_xpath("lowerValue")
        upper = attr_node.at_xpath("upperValue")
        expect(lower["xmi:id"]).to eq("EAID_LI000063_CD8A_48b4_BECD_FBFFBEAC015C")
        expect(lower["value"]).to eq("1")
        expect(upper["xmi:id"]).to eq("EAID_LI000064_CD8A_48b4_BECD_FBFFBEAC015C")
        expect(upper["value"]).to eq("1")
      ensure
        test_db.close_connection
      end
    end
  end
end
