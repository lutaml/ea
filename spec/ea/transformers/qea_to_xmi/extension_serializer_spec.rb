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
end
