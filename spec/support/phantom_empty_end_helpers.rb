# frozen_string_literal: true

module PhantomEmptyEndHelpers
  include LabelUpwardPropertyHelpers

  def end_texts(end_kind, style:, roles:, target_stereotype: nil)
    connector = Ea::Model::DiagramConnector.new(
      id: "up", relationship_ref: "up", connector_type: "Association", style: style,
      source_stereotype: nil, target_stereotype: target_stereotype
    )
    texts = phantom_end_renderer(roles).texts(
      text_box: PHANTOM_BOX, mult_box: PHANTOM_BOX, anchor: [100, 100], connector: connector, end_kind: end_kind
    )
    upward_property_coordinates(texts).keys
  end

  PHANTOM_BOX = { "ox" => 30, "oy" => 9, "cx" => 40, "cy" => 13, "alignment" => 0 }.freeze

  def phantom_end_renderer(roles)
    association = Ea::Model::Association.new(
      id: "up", source_id: "s", target_id: "t",
      source_role_name: roles[0], source_multiplicity_raw: roles[0] && "0..*",
      target_role_name: roles[1], target_multiplicity_raw: roles[1] && "1"
    )
    Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: { "up" => association }, document: nil,
      theme: Ea::Theme::Registry.default, font_family: "Cambria", font_size: 7, font_unit: "pt"
    )
  end
end
