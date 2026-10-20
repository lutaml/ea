# frozen_string_literal: true

module PrefixedNameHeaderHelpers
  def rendered_texts(document, diagram_name)
    diagram = document.diagrams.find { |d| d.name == diagram_name }
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    Nokogiri::XML(svg).xpath("//*[local-name()='text']").map(&:text)
  end
end
