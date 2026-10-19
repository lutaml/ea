# frozen_string_literal: true

module DefaultAttributeSeatHelpers
  def inherited_attribute_sizing_render(theme)
    placement = narrow_attribute_placement
    diagram = Ea::Model::Diagram.new(elements: [placement], theme: theme)
    renderer = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: { "klass" => narrow_attribute_model })
    row = Nokogiri::XML("<svg>#{renderer.render}</svg>").css("text").find do |node|
      node.text == "longAttributeName: String"
    end
    [placement.bounds, renderer.drawn_bounds.fetch("klass"), row]
  end

  def narrow_attribute_model
    Ea::Model::Klass.new(
      id: "klass", name: "Item",
      properties: [Ea::Model::Property.new(name: "longAttributeName", type_name: "String")]
    )
  end

  def narrow_attribute_placement
    Ea::Model::DiagramElement.new(
      model_element_ref: "klass", font_family: "Carlito", font_size: 9, font_size_unit: "pt",
      bounds: Ea::Model::Bounds.new(x: 100, y: 20, width: 40, height: 80)
    )
  end

  def attribute_seat_nodes(theme, family: "Carlito", size: 7)
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 100, y: 20, width: 150, height: 80),
      theme: theme, family: family, size: size, size_unit: "pt",
      attr_lines: ["+ value: Integer"], geometry: Struct.new(:attr_first_y).new(60)
    )
    svg = Ea::Svg::EaEmitter::Compartment::Attributes.render(context)
    Nokogiri::XML("<svg>#{svg}</svg>").css("text")
  end
end
