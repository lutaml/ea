# frozen_string_literal: true

module EnumCaptionHelpers
  def enum_caption_renderer(literals)
    classifier = Ea::Model::Enumeration.new(id: "enum", name: "Color", literals: literals)
    bounds = Ea::Model::Bounds.new(x: 0, y: 0, width: 150, height: 50)
    element = Ea::Model::DiagramElement.new(model_element_ref: "enum", bounds: bounds)
    diagram = Ea::Model::Diagram.new(elements: [element])
    Ea::Svg::EaEmitter::Elements.new(diagram, model_index: { "enum" => classifier })
  end
end
