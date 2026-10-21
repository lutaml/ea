# frozen_string_literal: true

module InstanceSlotInsetHelpers
  def basic_runstate_texts
    path = File.expand_path("../../examples/qea/basic.qea", __dir__)
    document = Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
    diagram = document.diagrams.find { |entry| entry.id == "3B8BD087-1683-46b1-8D0D-6F839C46C578" }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: true).render
    Nokogiri::XML(svg).remove_namespaces!.css("text")
  end

  def instance_slot_inset_node(family:, size:, unit:, inset:)
    theme = Ea::Theme::Definition.new(
      id: "custom-slot-inset",
      attribute_spec: Ea::Theme::Definition::AttrSpec.new(content_x_offset: inset)
    )
    instance = Ea::Model::InstanceSpecification.new(
      slots: [Ea::Model::Slot.new(name: "Variable A", value: "Value One")]
    )
    context = instance_slot_inset_context(instance, theme, family, size, unit)
    svg = Ea::Svg::EaEmitter::Compartment::InstanceSlots.render(context)
    Nokogiri::XML("<svg>#{svg}</svg>").at_css("text")
  end

  def instance_slot_inset_context(instance, theme, family, size, unit)
    Ea::Svg::EaEmitter::RenderContext.new(
      model_element: instance,
      bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 200, height: 100),
      geometry: Struct.new(:attr_first_y).new(50),
      family: family, size: size, size_unit: unit, theme: theme
    )
  end
end
