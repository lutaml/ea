# frozen_string_literal: true

module TagContentWidthHelpers
  def native_tag_document
    path = File.expand_path("../../examples/qea/simple.qea", __dir__)
    document = Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
    diagram = document.diagrams.find { |entry| entry.id == "204F4ACC-2230-4c8d-9861-EF5A6844B712" }
    [document, diagram]
  end

  def tag_width_render(values, width: 50, visible: true, unit: "pt", logical_height: nil)
    document = qea_tag_document(values)
    diagram = document.diagrams.first
    configure_tag_width_element(diagram.elements.first, width, visible, unit, logical_height)
    renderer = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: document.index_by_id)
    nodes = Nokogiri::XML("<svg>#{renderer.render}</svg>").remove_namespaces!
    [renderer.drawn_bounds.fetch("class").width, nodes]
  end

  def configure_tag_width_element(element, width, visible, unit, logical_height)
    element.bounds.width = width
    element.show_tagged_values = visible
    element.font_family = "Carlito"
    element.font_size = 9
    element.font_size_unit = unit
    element.font_logical_height = logical_height
  end
end
