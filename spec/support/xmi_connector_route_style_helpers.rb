# frozen_string_literal: true

module XmiConnectorRouteStyleHelpers
  def rendered_role_seat(path)
    document = Ea::Sources::Xmi::Adapter.from_path(path)
    diagram = document.diagrams.first
    connector = diagram.connectors.find { |item| item.relationship_ref.include?("3677D889") }
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    svg_document = Nokogiri::XML(svg)
    role = svg_document.xpath("//*[local-name()='text']")
                       .find { |node| node.text == "+indoorOpeningAttribute" }
    [connector, role]
  end
end
