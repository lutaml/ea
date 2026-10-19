# frozen_string_literal: true

module QeaAssociationClassHelpers
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists
  def render_association_class(subtype: "Class", class_id: "205", placed: true,
                               proxy_type: "ProxyConnector", classifier: "base-association",
                               class_bounds: [657, 601, 170, 88], second_classifier: classifier,
                               second_proxy: [515, 637, 14, 14])
    rows = Ea::Qea::Models
    objects = [203, 204].map do |id|
      rows::EaObject.new(ea_object_id: id, object_type: proxy_type, package_id: 1,
                         ea_guid: "proxy#{id}", classifier_guid: id == 203 ? classifier : second_classifier)
    end
    objects << rows::EaObject.new(ea_object_id: 205, object_type: "Class", name: "TexCoordList",
                                  ea_guid: "attached-class", package_id: 1)
    placements = [[203, 515, 637, 14, 14], [204, *second_proxy]]
    placements << [205, *class_bounds] if placed
    database = build_test_database(
      objects: objects,
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      connectors: [rows::EaConnector.new(
        connector_id: 223, connector_type: "Association", subtype: subtype, pdata1: class_id,
        start_object_id: 203, end_object_id: 204, direction: "Unspecified", ea_guid: "tether"
      )],
      diagrams: [rows::EaDiagram.new(diagram_id: 36, package_id: 1, diagram_type: "Logical",
                                     name: "D", ea_guid: "diagram", styleex: "SuppressFOC=1;")],
      diagram_objects: placements.map do |id, x, y, width, height|
        rows::EaDiagramObject.new(diagram_id: 36, ea_object_id: id, instance_id: id,
                                  rectleft: x, rectright: x + width,
                                  recttop: -y, rectbottom: -y - height)
      end,
      diagram_links: [rows::EaDiagramLink.new(
        diagramid: 36, connectorid: 223, instance_id: 213, hidden: 0,
        geometry: "EDGE=4;SX=0;SY=0;EX=0;EY=0;", style: "Mode=3;LWidth=0;"
      )]
    )
    document = Ea::Sources::Qea::Adapter.new(database, "association.qea").to_document
    diagram = document.diagrams.first
    elements = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: document.index_by_id, document: document)
    elements.render
    svg = Ea::Svg::EaEmitter::Connectors.new(
      diagram, model_index: document.index_by_id, drawn_bounds: elements.drawn_bounds
    ).render
    Nokogiri::XML("<svg>#{svg}</svg>").remove_namespaces!
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists
end
