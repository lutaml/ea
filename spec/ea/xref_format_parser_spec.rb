# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::Xref do
  let(:parser) { described_class::Parser }

  describe ".parse" do
    it "returns an empty record for nil" do
      record = parser.parse(nil)
      expect(record).to be_a(Ea::Sources::Qea::Xref::Record)
      expect(record.stereotype?).to be(false)
      expect(record.properties).to eq([])
    end

    it "returns an empty record for empty string" do
      record = parser.parse("")
      expect(record.properties).to eq([])
    end
  end

  describe "stereotype application parsing" do
    it "extracts Name and FQName from @STEREO block" do
      desc = "@STEREO;Name=FeatureType;FQName=GML::FeatureType;@ENDSTEREO;"
      stereo = parser.parse(desc).stereotype

      expect(stereo.name).to eq("FeatureType")
      expect(stereo.fqname).to eq("GML::FeatureType")
      expect(stereo.technology).to eq("GML")
      expect(stereo.unqualified_name).to eq("FeatureType")
    end

    it "handles legacy @STEREO format with GUID instead of @ENDSTEREO" do
      desc = "@STEREO;Name=boundary;GUID={ABC-123};"
      stereo = parser.parse(desc).stereotype

      expect(stereo.name).to eq("boundary")
      expect(stereo.fqname).to be_nil
    end

    it "returns nil stereotype when no @STEREO present" do
      record = parser.parse("@PROP=@NAME=x@ENDNAME;@ENDPROP;")
      expect(record.stereotype).to be_nil
    end

    it "handles FQName without :: technology prefix" do
      desc = "@STEREO;Name=X;FQName=NoPrefix;@ENDSTEREO;"
      stereo = parser.parse(desc).stereotype
      expect(stereo.technology).to be_nil
      # No "::" in FQName — fall back to Name field for the short form.
      expect(stereo.unqualified_name).to eq("X")
    end
  end

  describe "property definition parsing" do
    it "extracts NAME, TYPE, VALU, PRMT from @PROP block" do
      desc = "@PROP=@NAME=isActive@ENDNAME;@TYPE=Boolean@ENDTYPE;" \
             "@VALU=@ENDVALU;@PRMT=@ENDPRMT;@ENDPROP;"
      record = parser.parse(desc)

      expect(record.properties.size).to eq(1)
      prop = record.properties.first
      expect(prop).to be_a(Ea::Sources::Qea::Xref::PropertyDefinition)
      expect(prop.name).to eq("isActive")
      expect(prop.type).to eq("Boolean")
      expect(prop.boolean?).to be(true)
      expect(prop.default_value?).to be(false)
    end

    it "parses multiple consecutive @PROP blocks" do
      desc = "@PROP=@NAME=a@ENDNAME;@TYPE=String@ENDTYPE;@VALU=@ENDVALU;" \
             "@PRMT=@ENDPRMT;@ENDPROP;" \
             "@PROP=@NAME=b@ENDNAME;@TYPE=Integer@ENDTYPE;@VALU=42@ENDVALU;" \
             "@PRMT=@ENDPRMT;@ENDPROP;"
      record = parser.parse(desc)

      expect(record.properties.size).to eq(2)
      expect(record.properties[0].name).to eq("a")
      expect(record.properties[1].name).to eq("b")
      expect(record.properties[1].value).to eq("42")
      expect(record.properties[1].default_value?).to be(true)
    end
  end

  describe "legend definition parsing" do
    it "extracts legend entries with colors" do
      desc = "@PROP=@NAME=GML class@ENDNAME;@TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;" \
             "@VALU=#Back_Ground_Color#=13434828;#Pen_Color#=0;" \
             "#Pen_Size#=1;#Legend_Type#=LEGEND_OBJECTSTYLE;@ENDVALU;" \
             "@PRMT=0@ENDPRMT;@ENDPROP;"
      record = parser.parse(desc)

      expect(record.legends.size).to eq(1)
      legend = record.legends.first
      expect(legend).to be_a(Ea::Sources::Qea::Xref::LegendDefinition)
      expect(legend.name).to eq("GML class")
      expect(legend.legend_type).to eq("LEGEND_OBJECTSTYLE")
      expect(legend.colors[:back_ground_color]).to eq("13434828")
    end

    it "converts VB integer color to hex" do
      desc = "@PROP=@NAME=x@ENDNAME;@TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;" \
             "@VALU=#Back_Ground_Color#=13434828;@ENDVALU;@PRMT=0@ENDPRMT;@ENDPROP;"
      legend = parser.parse(desc).legends.first

      # 13434828 = 0xCCFFCC (VB OLE_COLOR BGR ≡ RGB after byte swap, but
      # EA stores RGB directly — verify against actual EA rendering).
      expect(legend.hex_color(:back_ground_color)).to eq("#CCFFCC")
    end
  end

  describe "legacy key=value parsing" do
    it "extracts fields outside of @STEREO and @PROP blocks" do
      desc = "aggregation=composite;direction=source;"
      record = parser.parse(desc)
      expect(record.key_values[:aggregation]).to eq("composite")
      expect(record.key_values[:direction]).to eq("source")
    end

    it "ignores key=value pairs inside @STEREO block" do
      desc = "@STEREO;Name=X;FQName=Y;@ENDSTEREO;extra=ok;"
      record = parser.parse(desc)
      expect(record.key_values).not_to have_key(:name)
      expect(record.key_values[:extra]).to eq("ok")
    end

    it "ignores key=value pairs inside @PROP blocks" do
      desc = "@PROP=@NAME=hidden@ENDNAME;@TYPE=String@ENDTYPE;@VALU=v@ENDVALU;" \
             "@PRMT=@ENDPRMT;@ENDPROP;visible=yes;"
      record = parser.parse(desc)
      expect(record.key_values).not_to have_key(:name)
      expect(record.key_values[:visible]).to eq("yes")
    end
  end

  describe "mixed content" do
    it "parses stereotype + properties + key_values together" do
      desc = "@STEREO;Name=FeatureType;FQName=GML::FeatureType;@ENDSTEREO;" \
             "@PROP=@NAME=isActive@ENDNAME;@TYPE=Boolean@ENDTYPE;@VALU=@ENDVALU;" \
             "@PRMT=@ENDPRMT;@ENDPROP;" \
             "extra=meta;"
      record = parser.parse(desc)

      expect(record.stereotype?).to be(true)
      expect(record.stereotype.name).to eq("FeatureType")
      expect(record.properties.size).to eq(1)
      expect(record.key_values[:extra]).to eq("meta")
      expect(record.raw).to eq(desc)
    end
  end
end
