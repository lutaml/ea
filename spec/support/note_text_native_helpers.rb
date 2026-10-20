# frozen_string_literal: true

module NoteTextNativeHelpers
  def native_note_text_context(left:, top:)
    bounds = Ea::Model::Bounds.new(x: left, y: top, width: 167, height: 84)
    geometry = Ea::Svg::EaEmitter::Element::CompartmentGeometry.new(
      bounds: bounds, size: 7, header_lines_count: 1,
      attr_lines_count: 0, op_lines_count: 0, tagged_values_count: 0
    )
    native_note_text_render_context(bounds, geometry)
  end

  def native_note_text_render_context(bounds, geometry)
    Ea::Svg::EaEmitter::RenderContext.new(
      bounds: bounds, classifier: native_note_text_classifier, geometry: geometry,
      diagram: Ea::Model::Diagram.new(id: "domain", show_notes: true, hand_draw: true),
      family: "Source Sans Pro", size: 7, size_unit: "pt",
      theme: Ea::Theme::Registry.lookup("119")
    )
  end

  def native_note_text_classifier
    Ea::Model::Klass.new(
      id: "concept", name: "Concept",
      annotations: [Ea::Model::Annotation.new(kind: "documentation",
                                              body: "[Detailed notes that describe the concept.]\n")]
    )
  end
end
