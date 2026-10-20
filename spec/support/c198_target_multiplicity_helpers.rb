# frozen_string_literal: true

module C198TargetMultiplicityHelpers
  def c198_target_multiplicity(target_face: [-1, 0], heading: [-215, 1], mult_box: {},
                               stereotype: "property", font: {})
    association, connector = c198_relationship(stereotype)
    font = { family: "Cambria", size: 7, unit: "pt" }.merge(font)
    renderer = c198_renderer(association, font)
    box = { "ox" => 0, "oy" => 0, "alignment" => 0 }.merge(mult_box)
    c198_positions(c198_markup(renderer, connector, box, heading, target_face))
  end

  def c198_relationship(stereotype)
    association = Ea::Model::Association.new(id: "relationship", target_role_name: "member",
                                             target_multiplicity_raw: "1")
    connector = Ea::Model::DiagramConnector.new(relationship_ref: association.id,
                                                connector_type: "Association",
                                                target_stereotype: stereotype,
                                                style: { mode: "3", lwidth: "2" })
    [association, connector]
  end

  def c198_renderer(association, font)
    Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: { association.id => association }, document: nil,
      theme: Ea::Theme::Registry.default, font_family: font[:family],
      font_size: font[:size], font_unit: font[:unit]
    )
  end

  def c198_markup(renderer, connector, box, heading, target_face)
    renderer.texts(text_box: { "ox" => 0, "oy" => 0, "alignment" => 0 }, mult_box: box,
                   anchor: [619, 508], connector: connector, end_kind: :target,
                   heading: heading, target_face: target_face).join
  end

  def c198_positions(markup)
    Nokogiri::XML.fragment(markup).css("text").to_h do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end

  def c198_target_face(target_box: Ea::Model::Bounds.new(x: 619, y: 451, width: 194, height: 91),
                       point: [619, 508], heading: [-215, 1])
    relationship = Ea::Model::Association.new(id: "relationship", source_id: "source", target_id: "target")
    connector = Ea::Model::DiagramConnector.new(relationship_ref: relationship.id)
    labels = Ea::Svg::EaEmitter::Labels.new(
      nil, model_index: { relationship.id => relationship },
           drawn_bounds: { "source" => Ea::Model::Bounds.new(x: 100, y: 400, width: 20, height: 20),
                           "target" => target_box }
    )
    labels.send(:target_dock_heading, connector, point, heading)
  end
end
