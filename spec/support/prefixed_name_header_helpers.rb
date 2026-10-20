# frozen_string_literal: true

module PrefixedNameHeaderHelpers
  def rendered_texts(document, diagram_name)
    diagram = document.diagrams.find { |d| d.name == diagram_name }
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    svg.scan(%r{<text[^>]*>([^<]*)</text>}).flatten
  end
end
