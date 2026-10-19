# frozen_string_literal: true

module CompactOperationSpacingHelpers
  def geometry(**overrides)
    Ea::Svg::EaEmitter::Element::CompartmentGeometry.new(**{
      bounds: Ea::Model::Bounds.new(x: 0, y: 10, width: 150, height: 200),
      size: 7, family: "Cambria", size_unit: "pt",
      header_lines_count: 1, attr_lines_count: 2, op_lines_count: 2,
      tagged_values_count: 0, compact_standard_operations: true
    }.merge(overrides))
  end
end
