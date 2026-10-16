# frozen_string_literal: true

module EnumInsetHelpers
  def enum_literal_node(size:, offset:, unit: "pt", family: "Carlito")
    theme = Ea::Theme::Definition.new(
      id: "custom", attribute_spec: Ea::Theme::Definition::AttrSpec.new(content_x_offset: offset)
    )
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 100, y: 20, width: 150, height: 80),
      theme: theme, family: family, size: size, size_unit: unit
    )
    literal = Ea::Model::EnumerationLiteral.new(name: "Blue")
    svg = Ea::Svg::EaEmitter::Compartment::EnumLiterals.literal_name_text(context, literal, 60)
    Nokogiri::XML(svg).at_xpath("//text")
  end
end
