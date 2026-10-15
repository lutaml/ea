# frozen_string_literal: true

module LabelUpwardPropertyHelpers
  def upward_property_positions(record, **options)
    connector = upward_property_connector(options)
    renderer = Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: upward_property_index(record, options),
      document: nil, theme: Ea::Theme::Registry.default, font_family: options.fetch(:family, "Cambria"),
      font_size: options.fetch(:size, 7), font_unit: options.fetch(:unit, "pt")
    )
    upward_property_texts(renderer, connector, record, options)
  end

  def upward_property_connector(options)
    Ea::Model::DiagramConnector.new(
      id: "up", relationship_ref: "up", source_stereotype: options.fetch(:stereotype, "property"),
      target_stereotype: options[:target_stereotype], connector_type: options.fetch(:type, "Association"),
      style: options.fetch(:style, { lwidth: "2" })
    )
  end

  def upward_property_index(record, options)
    { "up" => upward_property_association(record[:role], record.fetch(:mult, "0..1"), options[:end_kind]) }
  end

  def upward_property_association(role, mult, end_kind = nil)
    attributes = if end_kind == :target
                   { target_role_name: role, target_multiplicity_raw: mult }
                 else
                   { source_role_name: role, source_multiplicity_raw: mult }
                 end
    Ea::Model::Association.new(id: "up", source_id: "s", target_id: "t", **attributes)
  end

  def upward_property_texts(renderer, connector, record, options)
    texts = renderer.texts(
      text_box: options.fetch(:box, record[:box]), mult_box: options[:mult_box],
      anchor: record[:anchor], connector: connector, end_kind: options.fetch(:end_kind, :source),
      heading: options.fetch(:heading, [0, -100]), tree: options.fetch(:tree, false), stored_labels: true
    )
    upward_property_coordinates(texts)
  end

  def upward_property_coordinates(texts)
    Nokogiri::XML("<svg>#{texts.join}</svg>").css("text").to_h do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end
end
