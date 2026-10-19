# frozen_string_literal: true

module LegendItemFontHelpers
  def legend_source_texts(size:, logical_height:, unit: "pt", family: "Carlito")
    element = Ea::Model::DiagramElement.new(font_size: size, font_logical_height: logical_height)
    legend = Ea::Model::Legend.new(title: "Legend", heading_size: 16,
                                   items: [Ea::Model::LegendItem.new(name: "WWW")])
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 100, y: 50, width: 194, height: 120),
      element: element, model_element: Ea::Model::Note.new(legend: legend),
      family: family, size: size || 7, size_unit: unit, logical_height: logical_height
    )
    Nokogiri::XML("<svg>#{Ea::Svg::EaEmitter::Compartment::Shape.render(context)}</svg>").css("text")
  end
end
