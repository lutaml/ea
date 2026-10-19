# frozen_string_literal: true

module QeaRoutingHelpers
  # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/ParameterLists
  def render_qea_route(path:, style:, source: [100, 300, 200, 100],
                       target: [400, 100, 200, 100],
                       geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;",
                       connector_type: "Generalization", xrefs: [], connector_attributes: {},
                       object_styles: [nil, nil], target_placed: true)
    rows = Ea::Qea::Models
    placements = [source, target].take(target_placed ? 2 : 1)
    database = build_test_database(
      objects: [
        rows::EaObject.new(ea_object_id: 1, object_type: "Class", name: "Child",
                           ea_guid: "child", package_id: 1),
        rows::EaObject.new(ea_object_id: 2, object_type: "Class", name: "Parent",
                           ea_guid: "parent", package_id: 1)
      ],
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      xrefs: xrefs,
      connectors: [rows::EaConnector.new(
        connector_id: 1, connector_type: connector_type, start_object_id: 1,
        end_object_id: 2, direction: "Source -> Destination", ea_guid: "relationship", **connector_attributes
      )],
      diagrams: [rows::EaDiagram.new(
        diagram_id: 1, package_id: 1, diagram_type: "Logical", name: "D",
        ea_guid: "diagram", cx: 800, cy: 600, styleex: "SuppressFOC=1;"
      )],
      diagram_objects: placements.each_with_index.map do |(x, y, width, height), index|
        rows::EaDiagramObject.new(
          diagram_id: 1, ea_object_id: index + 1, instance_id: index + 1,
          rectleft: x, rectright: x + width, recttop: -y, rectbottom: -y - height,
          objectstyle: object_styles[index]
        )
      end,
      diagram_links: [rows::EaDiagramLink.new(
        diagramid: 1, connectorid: 1, geometry: geometry, style: style,
        path: path, hidden: 0, instance_id: 1
      )]
    )
    document = Ea::Sources::Qea::Adapter.new(database, "routing.qea").to_document
    yield document if block_given?
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
  # rubocop:enable Metrics/AbcSize,Metrics/MethodLength,Metrics/ParameterLists

  def qea_route_dividers(document)
    elements = Ea::Svg::EaEmitter::Elements.new(
      document.diagrams.first, model_index: document.index_by_id, document: document
    )
    elements.render
    elements.divider_y
  end

  def render_phantom(connector_type:)
    rows = Ea::Qea::Models
    database = build_test_database(
      objects: [1, 2].map do |id|
        rows::EaObject.new(ea_object_id: id, object_type: "Class", name: "C#{id}", ea_guid: "o#{id}", package_id: 1)
      end,
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      connectors: [rows::EaConnector.new(connector_id: 1, connector_type: connector_type, start_object_id: 1,
                                         end_object_id: 2, direction: "Source -> Destination", ea_guid: "r1")],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, package_id: 1, diagram_type: "Logical", name: "D",
                                     ea_guid: "diagram", cx: 800, cy: 600, styleex: "SuppressFOC=1;")],
      diagram_objects: [[1, 100, 300], [2, 100, 100]].map do |id, x, y|
        rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: id, instance_id: id,
                                  rectleft: x, rectright: x + 100, recttop: -y, rectbottom: -y - 100)
      end,
      diagram_links: []
    )
    document = Ea::Sources::Qea::Adapter.new(database, "phantom.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    Nokogiri::XML(svg).remove_namespaces!.css("path").map { |node| node["d"] }.first
  end
end
