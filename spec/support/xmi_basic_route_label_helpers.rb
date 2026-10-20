# frozen_string_literal: true

module XmiBasicRouteLabelHelpers
  def basic_route_label_diagram(prefix)
    @basic_route_label_document.diagrams.find { |diagram| diagram.id.include?(prefix) }
  end

  def basic_route_label_connector(prefix, relationship_prefix)
    basic_route_label_diagram(prefix).connectors.find do |connector|
      connector.relationship_ref.include?(relationship_prefix)
    end
  end

  def basic_route_label_text(prefix)
    document = @basic_route_label_document
    diagram = basic_route_label_diagram(prefix)
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    Nokogiri::XML(svg).remove_namespaces!.xpath("//text").map(&:text)
  end
end
