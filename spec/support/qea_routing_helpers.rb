# frozen_string_literal: true

module QeaRoutingHelpers
  # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  def render_qea_route(path:, style:, source: [100, 300, 200, 100],
                       target: [400, 100, 200, 100],
                       geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;")
    rows = Ea::Qea::Models
    database = build_test_database(
      objects: [
        rows::EaObject.new(ea_object_id: 1, object_type: "Class", name: "Child",
                           ea_guid: "child", package_id: 1),
        rows::EaObject.new(ea_object_id: 2, object_type: "Class", name: "Parent",
                           ea_guid: "parent", package_id: 1)
      ],
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      connectors: [rows::EaConnector.new(
        connector_id: 1, connector_type: "Generalization", start_object_id: 1,
        end_object_id: 2, direction: "Source -> Destination", ea_guid: "relationship"
      )],
      diagrams: [rows::EaDiagram.new(
        diagram_id: 1, package_id: 1, diagram_type: "Logical", name: "D",
        ea_guid: "diagram", cx: 800, cy: 600, styleex: "SuppressFOC=1;"
      )],
      diagram_objects: [source, target].each_with_index.map do |(x, y, width, height), index|
        rows::EaDiagramObject.new(
          diagram_id: 1, ea_object_id: index + 1, instance_id: index + 1,
          rectleft: x, rectright: x + width, recttop: -y, rectbottom: -y - height
        )
      end,
      diagram_links: [rows::EaDiagramLink.new(
        diagramid: 1, connectorid: 1, geometry: geometry, style: style,
        path: path, hidden: 0, instance_id: 1
      )]
    )
    document = Ea::Sources::Qea::Adapter.new(database, "routing.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(
      document.diagrams.first, model_index: document.index_by_id,
                               document: document, frame: false
    ).render
    xml = Nokogiri::XML(svg).remove_namespaces!
    {
      paths: xml.css("path").map { |node| node["d"] },
      markers: xml.css("polygon").map { |node| node["points"] }
    }
  end
  # rubocop:enable Metrics/AbcSize,Metrics/MethodLength
end
