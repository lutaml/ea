# frozen_string_literal: true

module ClassifierContentSizingHelpers
  def classifier_content_sizing_render(**options)
    options = { size: 9, family: "Carlito", unit: "pt", inset: 22, width: 40, height: 20 }.merge(options)
    placement = classifier_sizing_placement(options)
    diagram = classifier_sizing_diagram(placement, options[:inset])
    renderer = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: { "klass" => classifier_sizing_model })
    nodes = Nokogiri::XML("<svg>#{renderer.render}</svg>").xpath("//text")
    row = nodes.find { |node| node.text == "longAttributeName: String" }
    [placement.bounds, renderer.drawn_bounds.fetch("klass"), row]
  end

  def classifier_sizing_model
    Ea::Model::Klass.new(
      id: "klass", name: "Item",
      properties: [Ea::Model::Property.new(name: "longAttributeName", type_name: "String")]
    )
  end

  def classifier_sizing_placement(options)
    Ea::Model::DiagramElement.new(
      model_element_ref: "klass",
      bounds: Ea::Model::Bounds.new(x: 100, y: 20, width: options[:width], height: options[:height]),
      font_size: options[:size], font_family: options[:family], font_size_unit: options[:unit]
    )
  end

  def classifier_sizing_diagram(placement, inset)
    Ea::Model::Diagram.new(elements: [placement]).tap do |diagram|
      diagram.theme = Ea::Theme::Definition.new(
        id: "custom",
        attribute_spec: Ea::Theme::Definition::AttrSpec.new(content_x_offset: inset, visibility_x_offset: 5)
      )
    end
  end
end
