# frozen_string_literal: true

module QeaLegendAnchorHelpers
  def qea_legend_anchor_document(left:, top:)
    description = "@PROP=@NAME=Item@ENDNAME;@TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;" \
      "@VALU=#Back_Ground_Color#=13434828;@ENDVALU;@PRMT=0@ENDPRMT;@ENDPROP;" \
      "@PROP=@NAME=Legend@ENDNAME;@TYPE=LEGEND_STYLE_SETTINGS@ENDTYPE;" \
      "@VALU=#TITLE#=Legend;@ENDVALU;@PRMT=@ENDPRMT;@ENDPROP;"
    database = qea_legend_anchor_database(left: left, top: top, description: description)
    Ea::Sources::Qea::Adapter.new(database, "legend-anchor.qea").to_document
  end

  def qea_legend_anchor_database(left:, top:, description:)
    rows = Ea::Qea::Models
    build_test_database(
      objects: [rows::EaObject.new(ea_object_id: 1, object_type: "Text", name: "Legend",
                                   ea_guid: "legend", package_id: 1, styleex: "LegendOpts=1;")],
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      xrefs: [rows::EaXref.new(xref_id: "legend-xref", client: "legend",
                               name: Ea::Sources::Qea::LegendBuilder::LEGEND_XREF_NAME,
                               description: description)],
      **qea_legend_anchor_placement(left: left, top: top)
    )
  end

  def qea_legend_anchor_placement(left:, top:)
    rows = Ea::Qea::Models
    {
      diagrams: [rows::EaDiagram.new(diagram_id: 1, package_id: 1, diagram_type: "Logical",
                                     name: "D", ea_guid: "diagram", cx: 800, cy: 600)],
      diagram_objects: [rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: 1, instance_id: 1,
                                                  rectleft: left, rectright: left + 186,
                                                  recttop: -top, rectbottom: -(top + 95))]
    }
  end

  def rendered_legend_anchor_xml(document)
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    Nokogiri::XML(svg).remove_namespaces!
  end
end
