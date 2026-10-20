# frozen_string_literal: true

require "tempfile"
require "xmi"

module XmiObjectFontHelpers
  def with_xmi_object_font(styleex)
    Tempfile.create(["object-font", ".xmi"]) do |file|
      file.write(xmi_object_font_xml(styleex))
      file.flush
      root = Xmi::Sparx::Root.parse_xml(File.read(file.path))
      yield Ea::Sources::Xmi::DiagramBuilder.new(root, file.path)
    end
  end

  def xmi_object_font_xml(styleex)
    <<~XML
      <xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001">
        <xmi:Extension><elements>
          <element xmi:idref="EAID_LEGEND"><style styleex="#{styleex}"/></element>
          <element xmi:idref="EAID_OTHER"><style styleex="font=Other;fontsz=200;"/></element>
        </elements><diagrams><diagram xmi:id="EAID_DIAGRAM">
          <properties name="Object font" type="Logical"/>
          <elements><element subject="EAID_LEGEND" seqno="1"
            geometry="Left=78;Top=32;Right=264;Bottom=127;" style=""/></elements>
        </diagram></diagrams></xmi:Extension>
      </xmi:XMI>
    XML
  end

  def xmi_object_font_placement(builder, style)
    row = builder.root.extension.diagrams.diagram.first.elements.element.first
    row.style = style
    builder.build_all.first.elements.first
  end
end
