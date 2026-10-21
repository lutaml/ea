# frozen_string_literal: true

module XmiConnectorFallbackHelpers
  def fallback_connector_state(xml, connector_id)
    diagram = fallback_connector_diagram(xml, connector_id)
    return unless diagram

    connector = diagram.connectors.find { |item| item.relationship_ref == connector_id }
    [fallback_connector_models(diagram, connector),
     connector.waypoints.map { |point| [point.position.x, point.position.y] }]
  end

  def fallback_connector_diagram(xml, connector_id)
    parse_xmi(xml).diagrams.find do |diagram|
      diagram.connectors.any? { |connector| connector.relationship_ref == connector_id }
    end
  end

  def fallback_connector_models(diagram, connector)
    subjects = diagram.elements.to_h { |item| [item.id, item.model_element_ref] }
    [subjects[connector.source_element_ref], subjects[connector.target_element_ref]]
  end

  def without_saved_connector_ends(xmi_text, connector_id, remove_edge: false)
    doc = Nokogiri::XML(xmi_text)
    doc.xpath("//*[local-name()='element'][@subject='#{connector_id}']").each do |row|
      row["style"] = ";Hidden=0;"
      row["geometry"] = "SX=0;SY=0;EX=0;EY=0;EDGE=1;Path=;"
    end
    doc.xpath("//ownedElement[@modelElement='#{connector_id}']").remove if remove_edge
    doc.to_xml
  end
end
