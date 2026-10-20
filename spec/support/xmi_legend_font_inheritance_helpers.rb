# frozen_string_literal: true

require "xmi"
require "cgi"

module XmiLegendFontInheritanceHelpers
  def xmi_legend_placement(style)
    root = Xmi::Sparx::Root.parse_xml(xmi_legend_placement_xml(style))
    Ea::Sources::Xmi::DiagramBuilder.new(root).build_all.first.elements.first
  end

  def xmi_legend_placement_xml(style)
    <<~XML
      <xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001">
        <xmi:Extension><diagrams><diagram xmi:id="EAID_DIAGRAM">
          <properties name="Legend" type="Logical"/>
          <elements><element subject="EAID_LEGEND" seqno="1"
            geometry="Left=78;Top=32;Right=264;Bottom=127;" style="#{CGI.escapeHTML(style)}"/></elements>
        </diagram></diagrams></xmi:Extension>
      </xmi:XMI>
    XML
  end
end
