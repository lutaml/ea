# frozen_string_literal: true

module NoteShapeHelpers
  def note_shape_context(model, bounds)
    Ea::Svg::EaEmitter::RenderContext.new(
      model_element: model, bounds: bounds,
      fill: "#FFFFFF", stroke: "#000000", stroke_width: 2,
      text_fill: "#000000", family: "Carlito", size: 9, size_unit: "pt",
      theme: Ea::Theme::Registry.default
    )
  end

  def qea_note_shapes(document)
    document.diagrams.flat_map do |diagram|
      diagram.elements.filter_map do |placement|
        model = document.index_by_id[placement.model_element_ref]
        next unless model.is_a?(Ea::Model::Note) && model.body && !model.legend

        [model, placement.bounds]
      end
    end
  end
end
