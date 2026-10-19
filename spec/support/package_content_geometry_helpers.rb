# frozen_string_literal: true

module PackageContentGeometryHelpers
  def package_content_geometry_context(bounds, font, stereotype)
    family, size, unit = font
    package = Ea::Model::Package.new(id: "P", name: "Schema",
                                     stereotype_refs: [stereotype].compact)
    row = Ea::Svg::EaEmitter::Elements::PackageContentRow.new(name: "Foo", kind: :default)
    Ea::Svg::EaEmitter::RenderContext.new(
      bounds: bounds, model_element: package, family: family, size: size,
      size_unit: unit, theme: Ea::Theme::Registry.default, package_content_lines: [row]
    )
  end

  def package_content_body_top(context, stereotype)
    shape = Ea::Svg::EaEmitter::Element::PackageShapeRenderer.render(
      context.bounds, fill: "#FFFFFF", stroke: "#000000", stroke_width: 1,
                      label: "Schema", stereotype: stereotype, family: context.family,
                      size: context.size, size_unit: context.size_unit
    )
    Nokogiri::XML(shape).at_css("polygon")["points"].split[1].to_f
  end
end
