# frozen_string_literal: true

module NotelinkRedockHelpers
  include ConnectorRedockHelpers

  def notelink_fixture(border: 2, width: "0", type: "NoteLink")
    fixture = redock_fixture(type: type, width: width,
                             source: [170, 700, 140, 60], target: [450, 455, 380, 377],
                             points: [[310, 730], [830, 643]], anchors: [[240, 730], [640, 643]])
    fixture[:diagram].elements = [["s", 0], ["t", border]].map do |ref, line_width|
      Ea::Model::DiagramElement.new(model_element_ref: ref, line_width: line_width)
    end
    fixture
  end

  def notelink_pairs(fixture)
    Ea::Svg::EaEmitter::ConnectorRedock.pairs_for(
      fixture[:diagram].connectors.first, fixture[:diagram],
      fixture[:model_index], fixture[:drawn_bounds]
    )
  end

  def qea_notelink_document
    rows = Ea::Qea::Models
    database = build_test_database(
      objects: [
        rows::EaObject.new(ea_object_id: 1, object_type: "Note", name: "Note", ea_guid: "note",
                           package_id: 1, borderwidth: 0),
        rows::EaObject.new(ea_object_id: 2, object_type: "Class", name: "Population", ea_guid: "population",
                           package_id: 1, borderwidth: 2)
      ],
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      connectors: [rows::EaConnector.new(connector_id: 1, connector_type: "NoteLink",
                                         start_object_id: 1, end_object_id: 2, ea_guid: "relationship")],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, package_id: 1, diagram_type: "Logical",
                                     name: "D", ea_guid: "diagram", styleex: "SuppressFOC=1;")],
      diagram_objects: [[170, 700, 140, 60, 0], [450, 455, 380, 377, 2]].each_with_index.map do |rect, index|
        x, y, width, height, border = rect
        rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: index + 1, instance_id: index + 1,
                                  rectleft: x, rectright: x + width, recttop: -y, rectbottom: -y - height,
                                  objectstyle: "lwth=#{border};")
      end,
      diagram_links: [rows::EaDiagramLink.new(diagramid: 1, connectorid: 1,
                                              geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=2;",
                                              style: "Mode=3;LWidth=0;", hidden: 0, instance_id: 1)]
    )
    Ea::Sources::Qea::Adapter.new(database, "notelink.qea").to_document
  end
end
