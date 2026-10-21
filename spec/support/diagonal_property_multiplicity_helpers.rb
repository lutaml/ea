# frozen_string_literal: true

module DiagonalPropertyMultiplicityHelpers
  RELATIONSHIP_ID = "140847E2"

  def diagonal_property_texts(path, style_overrides = {})
    document = Ea::Sources::Xmi::Adapter.from_path(path)
    diagram = document.diagrams.first
    prepare_qea_like_connector(diagram, style_overrides)
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    text_positions(svg)
  end

  def prepare_qea_like_connector(diagram, style_overrides)
    connector = diagram.connectors.find { |item| item.relationship_ref.include?(RELATIONSHIP_ID) }
    connector.umldi_label_bounds = {}
    connector.style = connector.style.to_h.merge(style_overrides)
  end

  def text_positions(svg)
    nodes = Nokogiri::XML(svg).xpath("//*[local-name()='text']")
    nodes.to_h { |node| [node.text, [node["x"].to_f, node["y"].to_f]] }
  end
end
