# frozen_string_literal: true

module LegendHeadingFamilyHelpers
  def heading_family_texts(legend, family: "Calibri")
    bounds = Ea::Model::Bounds.new(x: 100, y: 50, width: 300, height: 120)
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: bounds, element: Ea::Model::DiagramElement.new,
      model_element: Ea::Model::Note.new(legend: legend), family: family,
      size: 9, size_unit: "pt"
    )
    svg = Ea::Svg::EaEmitter::Compartment::Shape.render(context)
    Nokogiri::XML("<svg>#{svg}</svg>").css("text")
  end

  def public_heading_family_texts(document, diagram_id)
    texts = compartment_texts(document, diagram_id)
    legend = document.index_by_id.fetch("4E5A37CB-F6FA-44ea-8762-5F379CFFB6A2").legend
    labels = unique_source_legend_labels(texts, legend)
    titles = texts.select { |node| node.text == legend.title }
    raise "Ambiguous legend title" unless titles.one?

    [labels, titles.first]
  end
end
