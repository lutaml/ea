# frozen_string_literal: true

module Issue135X5bLabelHelpers
  # The data sits on the opposite end; this end stores a box and a Property
  # stereotype only.
  def stereotype_only_target_positions(anchor, box)
    connector = upward_property_connector(style: { mode: "3", tree: "OS" }, stereotype: "property",
                                          target_stereotype: "property")
    association = Ea::Model::Association.new(id: "up", source_id: "s", target_id: "t",
                                             source_role_name: "lod1MultiSurface", source_multiplicity_raw: "0..1")
    renderer = Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: { "up" => association }, document: nil,
      theme: Ea::Theme::Registry.default, font_family: "Cambria", font_size: 7, font_unit: "pt"
    )
    upward_property_coordinates(renderer.texts(text_box: box, mult_box: nil, anchor: anchor, connector: connector,
                                               end_kind: :target, heading: [0, 166], stored_labels: true))
  end

  def centred_upward_positions(box)
    upward_property_positions({ role: "address", anchor: [384, 1479], box: box, mult: "0..*" },
                              style: { lwidth: "2" }, heading: [0, -158],
                              mult_box: { "ox" => -44, "oy" => -23, "cx" => 19, "cy" => 16, "alignment" => 1 })
  end

  def rightward_phantom_positions(style)
    zero = { "ox" => 0, "oy" => 0 }
    upward_property_positions({ role: "boundedBy", anchor: [912, 1377], box: zero },
                              style: style, heading: [1, 0], mult_box: zero)
  end

  def sloped_target_mult(stereotype, text_box, mult_box)
    upward_property_positions({ role: nil, anchor: [350, 367], box: text_box },
                              end_kind: :target, stereotype: stereotype, style: {},
                              heading: [110, -24], mult_box: mult_box).fetch("0..1")
  end

  def tree_target_mult(style, text_box, mult_box)
    upward_property_positions({ role: "+lod4Geometry", anchor: [460, 720], box: text_box },
                              end_kind: :target, style: style,
                              heading: [0, -325], mult_box: mult_box).fetch("0..1")
  end
end
