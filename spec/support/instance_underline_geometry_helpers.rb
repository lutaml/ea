# frozen_string_literal: true

module InstanceUnderlineGeometryHelpers
  def context_for(header_lines)
    diagram = Ea::Model::Diagram.new(id: "D1", name: "Object diagram",
                                     diagram_type: "Object")
    Ea::Svg::EaEmitter::RenderContext.new(
      element: nil, bounds: bounds, model_element: nil, classifier: nil,
      fill: "#FFF", stroke: "#000", stroke_width: 2,
      text_fill: "#000", family: "Carlito", size: 7, size_unit: "pt",
      logical_height: nil, header_lines: header_lines, attr_lines: [], op_lines: [],
      enum_literals: [], tagged_values: [], constraints: [],
      package_content_lines: [], geometry: geometry, theme: theme,
      canvas: nil, diagram: diagram
    )
  end
end
