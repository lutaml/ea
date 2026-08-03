# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/sources/qea/legend_builder"

RSpec.describe Ea::Sources::Qea::LegendBuilder do
  # Lightweight test double for the database — returns the same
  # xref list regardless of GUID (we test the parser, not lookup).
  TestDatabase = Struct.new(:xrefs) do
    def xrefs_for_client(_ea_guid)
      xrefs
    end
  end

  let(:description) do
    <<~DESC.freeze
      @PROP=@NAME=GMLに定義されたクラス@ENDNAME;@TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;@VALU=#Back_Ground_Color#=13434828;#Pen_Color#=0;#Pen_Size#=1;#Legend_Type#=LEGEND_OBJECTSTYLE;@ENDVALU;@PRMT=0@ENDPRMT;@ENDPROP;@PROP=@NAME=CityGMLに定義されたクラス@ENDNAME;@TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;@VALU=#Back_Ground_Color#=13434879;#Pen_Color#=0;#Pen_Size#=1;#Legend_Type#=LEGEND_OBJECTSTYLE;@ENDVALU;@PRMT=1@ENDPRMT;@ENDPROP;@PROP=@NAME=凡例@ENDNAME;@TYPE=LEGEND_STYLE_SETTINGS@ENDTYPE;@VALU=#TITLE#=凡例;@ENDVALU;@PRMT=@ENDPRMT;@ENDPROP;
    DESC
  end
  let(:xref) do
    Struct.new(:name, :description).new(
      Ea::Sources::Qea::LegendBuilder::LEGEND_XREF_NAME, description
    )
  end
  let(:database) { TestDatabase.new([xref]) }
  let(:builder) { described_class.new(database) }

  describe "#build_for" do
    it "returns nil when no matching xref exists for the GUID" do
      empty_db = TestDatabase.new([])
      expect(described_class.new(empty_db).build_for("{missing}")).to be_nil
    end

    it "returns nil when the xref description has no @PROP= blocks" do
      garbage = Struct.new(:name, :description).new(
        Ea::Sources::Qea::LegendBuilder::LEGEND_XREF_NAME, "garbage"
      )
      db = TestDatabase.new([garbage])
      expect(described_class.new(db).build_for("{guid}")).to be_nil
    end

    it "extracts the legend title from LEGEND_STYLE_SETTINGS" do
      legend = builder.build_for("{guid}")
      expect(legend.title).to eq("凡例")
    end

    it "parses one LegendItem per LEGEND_OBJECTSTYLE block, ordered by @PRMT=" do
      legend = builder.build_for("{guid}")
      expect(legend.items.size).to eq(2)
      expect(legend.items.map(&:name)).to eq([
                                                "GMLに定義されたクラス",
                                                "CityGMLに定義されたクラス"
                                              ])
      expect(legend.items.map(&:sort_index)).to eq([0, 1])
    end

    it "decodes BGR-packed Back_Ground_Color to the model integer" do
      legend = builder.build_for("{guid}")
      # 13434828 = 0xCCFFCC — BGR low-byte-R → SVG fill #CCFFCC.
      expect(legend.items[0].background_color).to eq(0xCCFFCC)
      # 13434879 = 0xCCFFFF → SVG fill #FFFFCC.
      expect(legend.items[1].background_color).to eq(0xCCFFFF)
    end

    it "falls back to default title when LEGEND_STYLE_SETTINGS lacks #TITLE#" do
      no_title = <<~DESC
        @PROP=@NAME=GMLに定義されたクラス@ENDNAME;@TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;@VALU=#Back_Ground_Color#=13434828;#Pen_Color#=0;#Pen_Size#=1;#Legend_Type#=LEGEND_OBJECTSTYLE;@ENDVALU;@PRMT=0@ENDPRMT;@ENDPROP;@PROP=@NAME=凡例@ENDNAME;@TYPE=LEGEND_STYLE_SETTINGS@ENDTYPE;@VALU=;@ENDVALU;@PRMT=@ENDPRMT;@ENDPROP;
      DESC
      db = TestDatabase.new([
        Struct.new(:name, :description).new(
          Ea::Sources::Qea::LegendBuilder::LEGEND_XREF_NAME, no_title
        )
      ])
      legend = described_class.new(db).build_for("{guid}")
      expect(legend.title).to eq(Ea::Model::Legend::DEFAULT_TITLE)
    end
  end
end
