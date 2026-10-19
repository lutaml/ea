# frozen_string_literal: true

module EnumContentWidthHelpers
  def enum_width_render(**options)
    options = { width: 190, name: "IfcUnitEnum", literal_name: "THERMODYNAMICTEMPERATUREUNIT",
                value: nil, size: 9, family: "Carlito", unit: "pt", logical_height: 13,
                offset: 22, background: nil, literals: true, marker: false }.merge(options)
    classifier = enum_width_classifier(options)
    element = enum_width_element(options)
    diagram = Ea::Model::Diagram.new(elements: [element])
    diagram.theme = Ea::Theme::Definition.new(
      id: "custom", attribute_spec: Ea::Theme::Definition::AttrSpec.new(content_x_offset: options[:offset])
    )
    enum_width_output(diagram, classifier)
  end

  def enum_width_classifier(options)
    literal = Ea::Model::EnumerationLiteral.new(name: options[:literal_name], value: options[:value])
    Ea::Model::Enumeration.new(
      id: "enum", name: options[:name], is_root: options[:marker],
      literals: options[:literals] ? [literal] : []
    )
  end

  def enum_width_element(options)
    Ea::Model::DiagramElement.new(
      model_element_ref: "enum", background_color: options[:background],
      bounds: Ea::Model::Bounds.new(x: 100, y: 20, width: options[:width], height: 180),
      font_size: options[:size], font_family: options[:family], font_size_unit: options[:unit],
      font_logical_height: options[:logical_height]
    )
  end

  def enum_width_output(diagram, classifier)
    renderer = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: { "enum" => classifier })
    nodes = Nokogiri::XML("<svg>#{renderer.render}</svg>").xpath("//text")
    [renderer, nodes]
  end
end
