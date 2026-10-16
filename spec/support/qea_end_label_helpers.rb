# frozen_string_literal: true

module QeaEndLabelHelpers
  LABEL_BOX = "CX=19:CY=16:OX=%<ox>d:OY=%<oy>d:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=0:DIR=0:ROT=0"

  # Renders one Association whose source end carries `member` / `0..*` and a
  # property stereotype, through the public QEA adapter. `boxes` holds the
  # stored label geometry; returns the connector path points and the
  # multiplicity text position.
  def render_qea_end_labels(path:, boxes:, source: [100, 300, 200, 100], target: [500, 300, 200, 100], **ends)
    database = build_test_database(**qea_end_label_tables(path, boxes, source, target, ends))
    document = Ea::Sources::Qea::Adapter.new(database, "end-labels.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    xml = Nokogiri::XML(svg).remove_namespaces!
    qea_end_label_result(xml, ends.fetch(:mult))
  end

  def qea_zero_boxes(*names)
    names.to_h { |name| [name, [0, 0]] }
  end

  def qea_end_label_result(xml, mult)
    points = xml.css("path").map { |node| node["d"] }.first.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a
    node = xml.css("text").find { |text| text.text == mult }
    { first: points.first, last: points.last, mult: node && [node["x"].to_f, node["y"].to_f] }
  end

  def qea_end_label_geometry(boxes)
    labels = boxes.map { |name, offsets| "#{name}=#{format(LABEL_BOX, ox: offsets[0], oy: offsets[1])}" }
    "SX=0;SY=0;EX=0;EY=0;EDGE=1;$#{labels.join(";")};"
  end

  def qea_end_label_tables(path, boxes, source, target, ends)
    rows = Ea::Qea::Models
    {
      objects: %w[Child Parent].each_with_index.map do |name, index|
        rows::EaObject.new(ea_object_id: index + 1, object_type: "Class", name: name,
                           ea_guid: name.downcase, package_id: 1)
      end,
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      connectors: [qea_end_label_connector(rows, ends)],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, package_id: 1, diagram_type: "Logical", name: "D",
                                     ea_guid: "diagram", cx: 900, cy: 600,
                                     styleex: "Theme=:119;SuppressFOC=1;")],
      diagram_objects: qea_end_label_placements(rows, source, target),
      diagram_links: [rows::EaDiagramLink.new(diagramid: 1, connectorid: 1, geometry: qea_end_label_geometry(boxes),
                                              style: ends.fetch(:style, "Mode=3;LWidth=2;"), path: path,
                                              hidden: 0, instance_id: 1)]
    }
  end

  def qea_end_label_connector(rows, ends)
    end_attributes = if ends[:end] == :target
                       { destrole: "member", destcard: ends.fetch(:mult), deststereotype: "property" }
                     else
                       { sourcerole: "member", sourcecard: ends.fetch(:mult), sourcestereotype: "property" }
                     end
    rows::EaConnector.new(connector_id: 1, connector_type: "Association", start_object_id: 1, end_object_id: 2,
                          direction: "Source -> Destination", ea_guid: "relationship", **end_attributes)
  end

  def qea_end_label_placements(rows, source, target)
    [source, target].each_with_index.map do |(x, y, width, height), index|
      rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: index + 1, instance_id: index + 1,
                                rectleft: x, rectright: x + width, recttop: -y, rectbottom: -y - height)
    end
  end
end
