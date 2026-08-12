# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Transformers::QeaToXmi::ExtensionSerializer do
  let(:database) { Ea::Qea.load("examples/qea/basic.qea") }
  let(:context) do
    Ea::Transformers::QeaToXmi::Context.new(database: database)
  end
  let(:serializer) { described_class.new(database, context) }

  after { database.close_connection }

  describe "#call" do
    subject(:output) { serializer.call }

    it "returns a non-empty string" do
      expect(output).to be_a(String)
      expect(output).not_to be_empty
    end

    it "includes <elements> section" do
      expect(output).to include("<elements>")
      expect(output).to include("</elements>")
    end

    it "includes <connectors> section" do
      expect(output).to include("<connectors>")
    end

    it "includes <diagrams> section" do
      expect(output).to include("<diagrams>")
    end

    it "emits per-element <style> blocks" do
      expect(output.scan(%r{<style[\s/>]}).size).to be > 50
    end

    it "emits per-element <tags> blocks" do
      expect(output.scan(%r{<tags[\s/>]}).size).to be > 50
    end

    it "emits <documentation> elements for attributes" do
      expect(output.scan(%r{<documentation[\s/>]}).size).to be > 10
    end
  end

  describe "UML_TYPE_FOR registry" do
    it "maps Class to uml:Class" do
      expect(described_class::UML_TYPE_FOR["Class"]).to eq("uml:Class")
    end

    it "maps Interface to uml:Interface" do
      expect(described_class::UML_TYPE_FOR["Interface"]).to eq("uml:Interface")
    end

    it "maps Enumeration to uml:Enumeration" do
      expect(described_class::UML_TYPE_FOR["Enumeration"]).to eq("uml:Enumeration")
    end

    it "maps PrimitiveType to uml:PrimitiveType" do
      expect(described_class::UML_TYPE_FOR["PrimitiveType"]).to eq("uml:PrimitiveType")
    end

    it "maps Association to uml:Association" do
      expect(described_class::UML_TYPE_FOR["Association"]).to eq("uml:Association")
    end
  end

  describe "SKIP_OBJECT_TYPES" do
    it "includes Note" do
      expect(described_class::SKIP_OBJECT_TYPES).to include("Note")
    end

    it "includes Text" do
      expect(described_class::SKIP_OBJECT_TYPES).to include("Text")
    end

    it "includes ProxyConnector" do
      expect(described_class::SKIP_OBJECT_TYPES).to include("ProxyConnector")
    end
  end

  describe "xrefs population" do
    subject(:output) { serializer.call }

    # Expected values copied verbatim from examples/exports/basic/model.xml.
    # Token order: $XID $NAM $TYP $VIS [$BEH] $PAR $DES $CLT [$SUP] $ENDXREF;
    # $BEH only when Behavior is non-blank. Blank Supplier: omitted for
    # "connector property", "<none>" for element/attribute property rows.
    it "emits the operation xref inside its operation" do
      expected = "$XREFPROP=$XID={62F035B9-1A09-47da-9E51-03D8FB66949B}$XID;" \
                 "$NAM=MOFProps$NAM;$TYP=operation property$TYP;$VIS=Public$VIS;" \
                 "$BEH=signal$BEH;$PAR=0$PAR;$DES={igna}$DES;" \
                 "$CLT={5F2256D3-8EEE-4371-8413-83233BCAF0E5}$CLT;" \
                 "$SUP={A53E4556-FAEE-458d-B9B2-93B41FA424AC}$SUP;$ENDXREF;"
      expect(output).to include(%(<xrefs value="#{expected}"/>))
    end

    it "omits $SUP for blank-supplier connector xrefs" do
      expected = "$XREFPROP=$XID={30D4BD91-0C67-43ff-8EE4-8C32314A4779}$XID;" \
                 "$NAM=Stereotypes$NAM;$TYP=connector property$TYP;$VIS=Public$VIS;" \
                 "$PAR=0$PAR;$DES=@STEREO;Name=import;" \
                 "GUID={4C1D99EB-03DD-45a8-B4EE-765741A43800};@ENDSTEREO;$DES;" \
                 "$CLT={12D9B35C-220D-4d31-A3DB-81BCEE4A226B}$CLT;$ENDXREF;"
      expect(output).to include(%(<xrefs value="#{expected}"/>))
    end

    it "emits all five populated xrefs basic's reference carries" do
      expect(output.scan(/<xrefs value="/).size).to eq(5)
    end

    it "renders blank suppliers as <none> on element-property xrefs" do
      test_db = Ea::Qea.load("examples/qea/test.qea")
      begin
        ctx = Ea::Transformers::QeaToXmi::Context.new(database: test_db)
        test_output = described_class.new(test_db, ctx).call
        expect(test_output.scan(/<xrefs value="/).size).to eq(22)
        expect(test_output).to include("$SUP=&lt;none&gt;$SUP;$ENDXREF;")
      ensure
        test_db.close_connection
      end
    end
  end

  describe "element entries for signals" do
    subject(:output) { serializer.call }

    it "uses the uml:Signal xmi:type in the extension section" do
      expect(output).to include(%(xmi:type="uml:Signal" name="Signal A"))
      expect(output).not_to include(%(xmi:type="Signal"))
    end
  end

  describe "primitivetypes section" do
    subject(:output) { serializer.call }

    it "emits the EAnone hierarchy with first-use ordering" do
      expect(output).to include(
        "\t\t<primitivetypes>\n" \
        "\t\t\t<packagedElement xmi:type=\"uml:Package\" xmi:id=\"EAPrimitiveTypesPackage\" name=\"EA_PrimitiveTypes_Package\">\n" \
        "\t\t\t\t<packagedElement xmi:type=\"uml:Package\" xmi:id=\"EAnoneTypesPackage\" name=\"EA_none_Types_Package\">\n" \
        "\t\t\t\t\t<packagedElement xmi:type=\"uml:PrimitiveType\" xmi:id=\"EAnone_typeOne\" name=\"typeOne\"/>\n" \
        "\t\t\t\t\t<packagedElement xmi:type=\"uml:PrimitiveType\" xmi:id=\"EAnone_typeTwo\" name=\"typeTwo\"/>\n" \
        "\t\t\t\t\t<packagedElement xmi:type=\"uml:PrimitiveType\" xmi:id=\"EAnone_typeThree\" name=\"typeThree\"/>\n" \
        "\t\t\t\t\t<packagedElement xmi:type=\"uml:PrimitiveType\" xmi:id=\"EAnone_void\" name=\"void\"/>\n" \
        "\t\t\t\t</packagedElement>\n" \
        "\t\t\t</packagedElement>\n" \
        "\t\t</primitivetypes>"
      )
    end
  end

  describe "diagram <elements> entries" do
    subject(:output) { serializer.call }

    # Expected entries copied verbatim from examples/exports/basic/model.xml
    # (Starter Object Diagram, t_diagramobjects rows for Diagram_ID=6 and the
    # first t_diagramlinks row). Object placements: geometry from the Rect*
    # columns (Top/Bottom sign-flipped, img* at fixed +25/+30 offsets),
    # seqno from Sequence, style from ObjectStyle verbatim. Connector
    # entries: subject is the CONNECTOR's EAID, geometry is the link's
    # Geometry plus "Path=<path>;", style is the link's Style plus
    # "Hidden=<hidden>;".
    it "emits object placements from t_diagramobjects" do
      geometry = "Left=315;Top=101;Right=405;Bottom=151;imgL=340;imgT=131;imgR=430;imgB=181;"
      expect(output).to include(
        %(<element geometry="#{geometry}" subject="EAID_FD9B2DCF_E737_471f_A86F_37BACFD69978" ) +
        %(seqno="1" style="DUID=F11A61F4;"/>)
      )
    end

    it "emits connector entries with the connector as subject" do
      style = "Mode=3;EOID=2B4926BE;SOID=79360F3F;Color=-1;LWidth=0;Hidden=0;"
      expect(output).to include(
        %(subject="EAID_1137B03A_C00A_443b_A3A8_D5CF6A7AFF13" style="#{style}"/>)
      )
    end

    it "rewrites Path waypoint separators to EA's $ form" do
      # t_diagramlinks stores "165:-230;371:-230;"; EA's reference emits
      # Path=165:-230$371:-230$; — verbatim from basic's export.
      expect(output).to include("Path=165:-230$371:-230$;")
      expect(output).not_to include("Path=165:-230;")
    end

    it "emits every placement and connector entry EA covers" do
      expect(output.scan(/<element geometry=/).size).to eq(168)
    end

    it "orders object placements by sequence before connector entries" do
      diagrams = output[%r{<diagrams>.*</diagrams>}m]
      elements = diagrams[%r{<elements>.*?</elements>}m].scan(/<element [^>]*>/)
      expect(elements[0]).to include(%(seqno="1"))
      expect(elements[1]).to include(%(seqno="2"))
    end
  end

  describe "placements with a NULL Sequence" do
    # t_diagramobjects.Sequence is nullable with DEFAULT 0.
    let(:object) do
      Ea::Qea::Models::EaObject.new(
        ea_object_id: 10, object_type: "Class", name: "C", package_id: 1,
        ea_guid: "{BBBBBBBB-1111-2222-3333-444444444444}"
      )
    end

    let(:diagram) do
      Ea::Qea::Models::EaDiagram.new(
        diagram_id: 7, package_id: 1, name: "D", diagram_type: "Logical",
        ea_guid: "{CCCCCCCC-1111-2222-3333-444444444444}"
      )
    end

    let(:placement) do
      Ea::Qea::Models::EaDiagramObject.new(
        diagram_id: 7, ea_object_id: 10, instance_id: 1, sequence: nil
      )
    end

    it "renders seqno as 0" do
      db = build_test_database(objects: [object], diagrams: [diagram], diagram_objects: [placement])
      context = Ea::Transformers::QeaToXmi::Context.new(database: db)
      expect(described_class.new(db, context).call).to include(%(seqno="0"))
    end
  end

  describe "operation <parameters>" do
    subject(:output) { serializer.call }

    it "emits one synthesized return parameter per typed operation" do
      expect(output.scan(/EAID_RETURNID_/).size).to eq(12)
    end

    it "puts the return parameter first, keyed off the operation id" do
      block = output[%r{<parameters>.*?</parameters>}m]
      expect(block.scan(/<parameter [^>]*>/).first)
        .to include(%(xmi:idref="EAID_RETURNID_))
      expect(block).to include(%(ea_guid="{RETURNID-))
    end

    it "orders parameters before xrefs inside an operation" do
      operation = output[%r{<operation [^>]*>.*?</operation>}m]
      expect(operation.index("<parameters>")).to be < operation.index("<xrefs")
    end
  end

  describe "a typed operation with no ea_guid" do
    # t_operation.ea_guid is nullable. The synthesized return entry
    # derives both its idref and its ea_guid from the operation's own
    # xmi id, so there is nothing to build it from here.
    let(:owner) do
      Ea::Qea::Models::EaObject.new(
        ea_object_id: 10, object_type: "Class", name: "C", package_id: 1,
        ea_guid: "{BBBBBBBB-1111-2222-3333-444444444444}"
      )
    end

    def output_for(ea_guid)
      operation = Ea::Qea::Models::EaOperation.new(
        operationid: 3, ea_object_id: 10, name: "count", type: "int",
        pos: 0, ea_guid: ea_guid
      )
      db = build_test_database(objects: [owner], operations: [operation])
      context = Ea::Transformers::QeaToXmi::Context.new(database: db)
      described_class.new(db, context).call
    end

    it "serializes without a return entry when the guid is nil" do
      expect(output_for(nil)).not_to include("EAID_RETURNID_")
    end

    it "serializes without a return entry when the guid is empty" do
      expect(output_for("")).not_to include("EAID_RETURNID_")
    end

    it "serializes without a return entry when the guid is whitespace" do
      expect(output_for("   ")).not_to include("EAID_RETURNID_")
    end
  end

  describe "an operation whose Type is whitespace only" do
    # PrimitiveTypes strips type names, so a whitespace-only Type is
    # absent as far as primitive discovery is concerned. Emitting a
    # return for it anyway produced type="   " in both trees with no
    # definition behind it.
    let(:database) do
      owner = Ea::Qea::Models::EaObject.new(
        ea_object_id: 10, object_type: "Class", name: "C", package_id: 1,
        ea_guid: "{BBBBBBBB-1111-2222-3333-444444444444}"
      )
      operation = Ea::Qea::Models::EaOperation.new(
        operationid: 3, ea_object_id: 10, name: "count", type: "   ",
        pos: 0, ea_guid: "{CCCCCCCC-1111-2222-3333-444444444444}"
      )
      # The package matters: without one the UML tree renders nothing
      # at all, and the ownedParameter assertion below could not fail.
      package = Ea::Qea::Models::EaPackage.new(
        package_id: 1, name: "P", parent_id: 0,
        ea_guid: "{AAAAAAAA-1111-2222-3333-444444444444}"
      )
      build_test_database(objects: [owner], operations: [operation],
                          packages: [package])
    end

    it "emits no extension return entry" do
      context = Ea::Transformers::QeaToXmi::Context.new(database: database)
      expect(described_class.new(database, context).call)
        .not_to include("EAID_RETURNID_")
    end

    it "emits no return ownedParameter in the UML tree" do
      xml = Ea::Transformers::QeaToXmi::Transformer.new(database)
                                                   .serialize(with_extensions: false)
      expect(xml).not_to include(%(direction="return"))
    end
  end

  describe "attribute <bounds> with blank EA columns" do
    # `attr.lowerbound || 1` only caught nil, so a blank string used to
    # render lower="" here while the UML tree said 1..1.
    let(:owner) do
      Ea::Qea::Models::EaObject.new(
        ea_object_id: 10, object_type: "Class", name: "C", package_id: 1,
        ea_guid: "{BBBBBBBB-1111-2222-3333-444444444444}"
      )
    end

    def output_for(lowerbound, upperbound)
      attribute = Ea::Qea::Models::EaAttribute.new(
        id: 5, ea_object_id: 10, name: "a", type: "int",
        lowerbound: lowerbound, upperbound: upperbound,
        ea_guid: "{DDDDDDDD-1111-2222-3333-444444444444}"
      )
      db = build_test_database(objects: [owner], attributes: [attribute])
      context = Ea::Transformers::QeaToXmi::Context.new(database: db)
      described_class.new(db, context).call
    end

    it "defaults empty strings to EA's explicit 1..1" do
      expect(output_for("", "")).to include(%(<bounds lower="1" upper="1"/>))
    end

    it "defaults whitespace-only columns to EA's explicit 1..1" do
      expect(output_for(" ", " ")).to include(%(<bounds lower="1" upper="1"/>))
    end

    it "agrees with the UML tree when only one column is set" do
      expect(output_for("2", "")).to include(%(<bounds lower="2" upper="*"/>))
    end

    # EA's bound columns are free text, so they carry the same XML
    # metacharacters every other attribute value here is escaped for.
    it "escapes markup characters instead of corrupting the document" do
      expect(output_for("1&2", %(3"4)))
        .to include(%(<bounds lower="1&amp;2" upper="3&quot;4"/>))
    end

    it "keeps the whole document well-formed" do
      attribute = Ea::Qea::Models::EaAttribute.new(
        id: 5, ea_object_id: 10, name: "a", type: "int",
        lowerbound: "1&2", upperbound: %(3"4),
        ea_guid: "{DDDDDDDD-1111-2222-3333-444444444444}"
      )
      db = build_test_database(objects: [owner], attributes: [attribute])
      xml = Ea::Transformers::QeaToXmi::Transformer.new(db).serialize
      expect(Nokogiri::XML(xml).errors).to be_empty
    end
  end

  describe "declared parameter ordering" do
    # t_operationparams is loaded unordered. The UML tree sorts by Pos,
    # so the extension block has to as well or the two renderers
    # disagree about the parameter list.
    let(:owner) do
      Ea::Qea::Models::EaObject.new(
        ea_object_id: 10, object_type: "Class", name: "C", package_id: 1,
        ea_guid: "{BBBBBBBB-1111-2222-3333-444444444444}"
      )
    end

    let(:operation) do
      Ea::Qea::Models::EaOperation.new(
        operationid: 7, ea_object_id: 10, name: "m", type: "void",
        ea_guid: "{0000000A-1111-2222-3333-444444444444}"
      )
    end

    def parameter(name, pos, guid)
      Ea::Qea::Models::EaOperationParam.new(
        operationid: 7, name: name, type: "int", pos: pos, ea_guid: guid
      )
    end

    it "emits them in Pos order regardless of insertion order" do
      later = parameter("second", 2, "{0000000B-1111-2222-3333-444444444444}")
      earlier = parameter("first", 1, "{0000000C-1111-2222-3333-444444444444}")
      db = build_test_database(objects: [owner], operations: [operation],
                               operation_params: [later, earlier])
      context = Ea::Transformers::QeaToXmi::Context.new(database: db)
      output = described_class.new(db, context).call
      expect(output.scan(/<properties pos="(\d+)"/).flatten).to eq(%w[0 1 2])
    end
  end
end
