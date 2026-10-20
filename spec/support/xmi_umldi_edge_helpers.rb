# frozen_string_literal: true

require "tmpdir"

module XmiUmldiEdgeHelpers
  def umldi_route(edges_xml, connector_id)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "model.xmi")
      File.write(path, umldi_document(edges_xml))
      Ea::Sources::Xmi::DiagramBuilder::UmldiEdges.new(path).route_for("D1", connector_id)
    end
  end

  def umldi_edge(connector_id, points)
    waypoints = points.map { |x, y| %(<waypoint x="#{x}" y="#{y}"/>) }.join
    %(<ownedElement type="umldi:UMLEdge" modelElement="#{connector_id}">#{waypoints}</ownedElement>)
  end

  def umldi_document(edges_xml)
    %(<xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001">
        <umldi:Diagram xmlns:umldi="http://www.omg.org/spec/UML/20161101/UMLDI" xmi:id="D1">#{edges_xml}</umldi:Diagram>
      </xmi:XMI>)
  end

  def plateau_xmi_points(diagram_guid, connector_guid)
    skip "plateau XMI unavailable" unless File.exist?(plateau_xmi_path)
    xmi_connector_points("{#{diagram_guid}}", "{#{connector_guid}}")
  end
end
