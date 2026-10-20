# frozen_string_literal: true

module NoteTextSeparatorHelpers
  def documentation_rows(body, width:, shown: true)
    classifier = Ea::Model::Classifier.new(id: "C1", annotations: [Ea::Model::Annotation.new(body: body)])
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: width, height: 100),
      classifier: classifier, diagram: Ea::Model::Diagram.new(show_notes: shown),
      family: "Source Sans Pro", size: 7, size_unit: "pt",
      geometry: Struct.new(:attr_first_y).new(30), theme: Ea::Theme::Registry.default
    )
    svg = Ea::Svg::EaEmitter::Compartment::NoteText.render(context)
    Nokogiri::XML.fragment(svg.to_s).css("text")
  end
end
