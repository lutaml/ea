# frozen_string_literal: true

module TrailingCompartmentFontHelpers
  def trailing_tag_nodes(size_unit:, logical_height:)
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 200),
      geometry: Struct.new(:tagged_value_first_y).new(50),
      tagged_values: [Ea::Model::TaggedValue.new(key: "HighPrecision", value: "false")],
      family: "Carlito", size: 9, size_unit: size_unit, logical_height: logical_height
    )
    svg = Ea::Svg::EaEmitter::Compartment::TaggedValues.render(context)
    Nokogiri::XML("<svg>#{svg}</svg>").css("text")
  end

  def trailing_slot_nodes(size_unit:, logical_height:)
    context = Ea::Svg::EaEmitter::RenderContext.new(
      model_element: trailing_slot_instance,
      bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 200, height: 200),
      geometry: Struct.new(:attr_first_y).new(50),
      family: "Carlito", size: 9, size_unit: size_unit, logical_height: logical_height,
      theme: Ea::Theme::Registry.lookup("119")
    )
    svg = Ea::Svg::EaEmitter::Compartment::InstanceSlots.render(context)
    Nokogiri::XML("<svg>#{svg}</svg>").css("text")
  end

  def trailing_slot_instance
    Ea::Model::InstanceSpecification.new(
      name: "Instance", package_name: "Foreign", classifier_name: "Classifier",
      slots: [Ea::Model::Slot.new(name: "HighPrecision", value: "false")]
    )
  end

  def trailing_tag_public_nodes
    path = File.expand_path("../../examples/qea/simple.qea", __dir__)
    document = Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
    diagram = document.diagrams.find { |entry| entry.id == "204F4ACC-2230-4c8d-9861-EF5A6844B712" }
    trailing_public_text_nodes(document, diagram).select do |node|
      node.text == "tags" || node.text.include?(" = ")
    end
  end

  def trailing_public_text_nodes(document, diagram)
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: true).render
    Nokogiri::XML(svg).remove_namespaces!.css("text")
  end
end
