# frozen_string_literal: true

module XmiLegendFontInheritanceHelpers
  def xmi_legend_placement(style)
    placed = Ea::Sources::Xmi::ExtensionElements::PlacedElement.new(
      subject: "EAID_LEGEND", seqno: 1,
      geometry: Ea::Sources::Xmi::ExtensionGeometryParser.parse(
        "Left=78;Top=32;Right=264;Bottom=127;"
      ),
      style: Ea::Sources::Xmi::ExtensionStyleParser.parse(style)
    )
    Ea::Sources::Xmi::DiagramBuilder.new(nil).send(:build_element, placed, "diagram")
  end
end
