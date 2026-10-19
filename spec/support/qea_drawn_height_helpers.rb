# frozen_string_literal: true

module QeaDrawnHeightHelpers
  def qea_compartment_bounds(document, diagram_id, name)
    model_index = document.index_by_id
    diagram = document.diagrams.find { |entry| entry.id == diagram_id }
    placement = diagram.elements.find { |entry| model_index.fetch(entry.model_element_ref).name == name }
    renderer = Ea::Svg::EaEmitter::Elements.new(
      diagram, model_index: model_index, document: document
    )
    renderer.render
    [placement.bounds, renderer.drawn_bounds.fetch(placement.model_element_ref)]
  end
end
