# frozen_string_literal: true

module ObjectSlotLayoutHelpers
  def object_slot_public_nodes(diagram_id)
    path = File.expand_path("../../examples/qea/basic.qea", __dir__)
    document = Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
    diagram = document.diagrams.find { |entry| entry.id == diagram_id }
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    Nokogiri::XML(svg).remove_namespaces!.css("text")
  end

  def object_slot_nodes(context)
    svg = Ea::Svg::EaEmitter::Compartment::InstanceSlots.render(context)
    Nokogiri::XML("<svg>#{svg}</svg>").css("text")
  end

  def object_slot_control_context(family:, size:, unit:, height: nil)
    instance = Ea::Model::InstanceSpecification.new(
      slots: %w[One Two Three].map { |name| Ea::Model::Slot.new(name: name, value: "value") }
    )
    Ea::Svg::EaEmitter::RenderContext.new(
      model_element: instance,
      bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 200, height: 100),
      geometry: Struct.new(:attr_first_y).new(50),
      family: family, size: size, size_unit: unit, logical_height: height,
      theme: object_slot_control_theme
    )
  end

  def object_slot_control_theme
    Ea::Theme::Definition.new(
      id: "slot-control", attribute_spec: Ea::Theme::Definition::AttrSpec.new(content_x_offset: 40)
    )
  end
end
