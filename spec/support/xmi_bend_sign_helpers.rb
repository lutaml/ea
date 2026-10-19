# frozen_string_literal: true

module XmiBendSignHelpers
  def parsed_bends(path)
    Ea::Sources::Xmi::ExtensionGeometryParser.parse("EDGE=1;Path=#{path};").bend_points
  end

  def xmi_connector_points(diagram_guid, connector_guid)
    _doc, diagram = plateau_xmi_diagram(diagram_guid)
    key = connector_guid.delete("{}").tr("-", "_").upcase
    connector = diagram.connectors.find { |c| c.relationship_ref.to_s.upcase.include?(key) }
    connector.waypoints.map { |w| [w.position.x, w.position.y] }
  end

  def qea_connector_points(diagram_guid, connector_guid)
    _doc, diagram = plateau_diagram(diagram_guid)
    connector = diagram.connectors.find { |c| c.relationship_ref.to_s.casecmp?(connector_guid.delete("{}")) }
    connector.waypoints.map { |w| [w.position.x, w.position.y] }
  end

  # Native SVG element rects anchor the canvas: the shift between a model
  # element's bounds and the native <rect> of identical size.
  def native_shift(diagram_guid, element_guid)
    _doc, diagram = plateau_xmi_diagram(diagram_guid)
    bounds = diagram.elements.find { |e| e.id.to_s.upcase.end_with?(element_guid.tr("-", "_").upcase) }.bounds
    rect = native_rects(diagram.id).find { |r| r.values_at(2, 3) == [bounds.width, bounds.height] }
    [rect[0] - bounds.x, rect[1] - bounds.y]
  end

  def native_rects(diagram_id)
    svg = File.read(File.join(File.dirname(plateau_xmi_path), "Images", "#{diagram_id}.svg"))
    svg.scan(/<rect x="(\d+)" y="(\d+)" width="(\d+)" height="(\d+)"/).map { |r| r.map(&:to_i) }
  end
end
