# frozen_string_literal: true

module LegendSourceDefaultHelpers
  def source_default_legend_svg(element:, size: 7, unit: "pt")
    legend = Ea::Model::Legend.new(title: "Legend", heading_size: 16,
                                   items: [Ea::Model::LegendItem.new(name: "WWW")])
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 100, y: 50, width: 194, height: 120),
      element: element, model_element: Ea::Model::Note.new(legend: legend),
      family: "Cambria", size: size, size_unit: unit
    )
    Nokogiri::XML("<svg>#{Ea::Svg::EaEmitter::Compartment::Shape.render(context)}</svg>")
  end

  def source_default_qea_legend(document, diagram_id, object_id)
    diagram = document.diagrams.find { |entry| entry.id == diagram_id }
    placement = diagram.elements.find { |entry| entry.model_element_ref == object_id }
    legend = document.index_by_id.fetch(object_id).legend
    texts = compartment_texts(document, diagram_id)
    labels = unique_source_legend_labels(texts, legend)
    [placement, labels]
  end

  def unique_source_legend_labels(texts, legend)
    legend.items.map do |item|
      matches = texts.select { |text| text.text == item.name }
      raise "Ambiguous legend label" unless matches.one?

      matches.first
    end
  end
end
