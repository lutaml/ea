# frozen_string_literal: true

module QeaBorderWidthHelpers
  def border_width_document(placement: "LWth=-1;", object_width: -1)
    rows = Ea::Qea::Models
    database = build_test_database(
      objects: [rows::EaObject.new(ea_object_id: 1, ea_guid: "s", object_type: "Class", name: "S",
                                   borderwidth: object_width)],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, ea_guid: "d", styleex: "Theme=:119;SuppressFOC=1;")],
      diagram_objects: [rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: 1, instance_id: 1,
                                                  objectstyle: placement, rectleft: 0, rectright: 100,
                                                  recttop: 0, rectbottom: -100)]
    )
    Ea::Sources::Qea::Adapter.new(database, "width.qea").to_document
  end

  def rendered_border_width(document)
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    rectangle = Nokogiri::XML(svg).remove_namespaces!.at_css("rect[rx]")
    rectangle.parent["style"][/stroke-width:([^;]+)/, 1].to_i
  end
end
