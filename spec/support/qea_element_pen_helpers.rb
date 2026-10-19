# frozen_string_literal: true

module QeaElementPenHelpers
  def element_pen_document(placement: nil, object_color: -1)
    rows = Ea::Qea::Models
    database = build_test_database(
      objects: [rows::EaObject.new(ea_object_id: 1, ea_guid: "pen-class", object_type: "Class",
                                   name: "PenClass", bordercolor: object_color)],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, ea_guid: "pen-diagram", styleex: "Theme=:119;SuppressFOC=1;")],
      diagram_objects: [rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: 1, instance_id: 1,
                                                  objectstyle: placement, rectleft: 0, rectright: 100,
                                                  recttop: 0, rectbottom: -100)]
    )
    Ea::Sources::Qea::Adapter.new(database, "pen.qea").to_document
  end

  def rendered_element_pen(document)
    svg = Ea::Svg::EaEmitter::Elements.new(document.diagrams.first,
                                           model_index: document.index_by_id, document: document).render
    rectangle = Nokogiri::XML("<svg>#{svg}</svg>").at_css("rect[rx]")
    rectangle.parent["style"][/stroke:([^;]+)/, 1]
  end
end
