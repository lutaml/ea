# frozen_string_literal: true

require "tempfile"

module XmiLegendNotesHelpers
  LEGEND_DESCRIPTION =
    "@PROP=@NAME=Alpha@ENDNAME;@TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;" \
    "@VALU=#Back_Ground_Color#=12648352;#Pen_Color#=0;#Pen_Size#=1;" \
    "@ENDVALU;@PRMT=0@ENDPRMT;@ENDPROP;" \
    "@PROP=@NAME=Beta@ENDNAME;@TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;" \
    "@VALU=#Back_Ground_Color#=13434879;#Pen_Color#=5;#Pen_Size#=2;" \
    "@ENDVALU;@PRMT=1@ENDPRMT;@ENDPROP;" \
    "@PROP=@NAME=Title@ENDNAME;@TYPE=LEGEND_STYLE_SETTINGS@ENDTYPE;" \
    "@VALU=#TITLE#=Key;#HEADINGSIZE#=16;#FONTCOLOR#=6303744;" \
    "#BACKGROUNDCOLOR#=11646651;#BORDERCOLOR#=10659756;" \
    "#BACKGROUNDISDEFAULT#=0;@ENDVALU;@PRMT=@ENDPRMT;@ENDPROP;"

  def text_note_elements
    <<~XML
      <elements>
      <element xmi:idref="EAID_LEG1" xmi:type="uml:Text" name="" scope="public">
        <properties isSpecification="false" sType="Text" nType="76" scope="public"/>
        <xrefs value="$XREFPROP=$NAM=CustomProperties$NAM;$DES=#{LEGEND_DESCRIPTION}$DES;$ENDXREF;"/>
      </element>
      <element xmi:idref="EAID_TXT1" xmi:type="uml:Text" name="plain" scope="public">
        <properties documentation="free text" sType="Text" nType="76" scope="public"/>
        <xrefs/>
      </element>
      <element xmi:idref="EAID_NOTE1" xmi:type="uml:Note" name="" scope="public">
        <properties documentation="a note" sType="Note" nType="0" scope="public"/>
      </element>
    XML
  end

  def adapter_with_text_notes
    source = File.read(File.expand_path("../fixtures/basic.xmi", __dir__))
    patched = source.sub("<elements>\n", text_note_elements)
    Tempfile.create(["legend", ".xmi"]) do |file|
      file.write(patched)
      file.flush
      Ea::Sources::Xmi::Adapter.from_path(file.path)
    end
  end
end
