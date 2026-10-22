# frozen_string_literal: true

module EndLabelLeftSeatHelpers
  def left_seat_label_xs(label_class, role, anchor)
    source = Ea::Model::Property.new(id: "p_src", name: role, owner_id: "c1", visibility: "public",
                                     multiplicity_lower: 0, multiplicity_upper: -1)
    target = Ea::Model::Property.new(id: "p_tgt", name: "tgt", owner_id: "c2", visibility: "public",
                                     multiplicity_lower: 1, multiplicity_upper: 1)
    document = Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [Ea::Model::Klass.new(id: "c1", name: "A", properties: [source]),
                    Ea::Model::Klass.new(id: "c2", name: "B", properties: [target])],
      relationships: [Ea::Model::Association.new(id: "r1", source_id: "p_src", target_id: "p_tgt")]
    )
    points = [[0, 0], [100, 0]].map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) }
    connector = Ea::Model::DiagramConnector.new(
      id: "dc1", relationship_ref: "r1", connector_type: "Association", direction: "Source -> Destination",
      waypoints: points, style: { left_seated_source: true },
      label_boxes: { llb: { "ox" => 0, "oy" => 0 }, llt: { "ox" => 10, "oy" => 15 } }
    )
    label = label_class.new(canvas: nil, model_index: document.index_by_id, document: document,
                            theme: Ea::Theme::Registry.default, font_family: "Carlito", font_size: 7,
                            font_unit: "pt")
    texts = label.texts(text_box: { "ox" => 10, "oy" => 15, "cx" => 40, "cy" => 12 },
                        mult_box: { "ox" => 0, "oy" => 0, "cx" => 20, "cy" => 12 }, anchor: anchor,
                        connector: connector, end_kind: :source, heading: [-1, 0], tree: false)
    texts.map { |text| text[/x="([^"]*)"/, 1].to_f }
  end
end
