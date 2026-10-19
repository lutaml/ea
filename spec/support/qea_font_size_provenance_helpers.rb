# frozen_string_literal: true

module QeaFontSizeProvenanceHelpers
  def font_provenance_element(placement: nil, classifier: nil)
    rows = Ea::Qea::Models
    database = build_test_database(
      objects: [rows::EaObject.new(ea_object_id: 1, ea_guid: "font-class", object_type: "Class",
                                   name: "FontClass", styleex: classifier)],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, ea_guid: "font-diagram", styleex: "Theme=:119;")],
      diagram_objects: [rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: 1, instance_id: 1,
                                                  objectstyle: placement, rectleft: 0, rectright: 100,
                                                  recttop: 0, rectbottom: -100)]
    )
    Ea::Sources::Qea::Adapter.new(database, "font.qea").to_document.diagrams.first.elements.first
  end
end
