# frozen_string_literal: true

module OperationInsetHelpers
  def operation_inset_nodes(family:, size:, unit: "pt", visibility: "public")
    operation = Ea::Model::Operation.new(name: "resize", visibility: visibility)
    operation.parameters = [Ea::Model::Parameter.new(name: "width", type_name: "int")]
    operation.return_type_name = "void"
    bounds = Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 80)
    svg = Ea::Svg::EaEmitter::Element::OperationRenderer.render(
      [operation], bounds: bounds, first_y: 50, family: family, size: size, size_unit: unit
    )
    Nokogiri::XML("<svg>#{svg}</svg>").css("text")
  end
end
