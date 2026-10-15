# frozen_string_literal: true

# Renders one association connector's end labels through
# Ea::Svg::EaEmitter::Labels (the public entry point) and returns the
# emitted [content, [x, y]] pairs in document order (source end first).
module LabelSeatHelpers
  def label_seat_positions(waypoints:, label_boxes:, role: "items",
                           multiplicity: "0..*", stereotype: nil,
                           font_size: 7)
    document = label_seat_document(waypoints, label_boxes, role,
                                   multiplicity, stereotype)
    labels = Ea::Svg::EaEmitter::Labels.new(
      document.diagrams.first,
      model_index: document.index_by_id, document: document,
      theme: label_seat_theme(font_size)
    )
    Nokogiri::XML(%(<svg>#{labels.render}</svg>)).css("text").map do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end

  def label_seat_theme(font_size)
    return Ea::Theme::Registry.default unless font_size

    Ea::Theme::Definition.new(id: "label-seat", font_family: "Carlito",
                              font_size: font_size, font_size_unit: "pt")
  end

  def label_seat_document(waypoints, label_boxes, role, multiplicity,
                          stereotype)
    association = Ea::Model::Association.new(
      id: "r1", source_id: "c1", target_id: "c2",
      source_role_name: role, source_multiplicity_raw: multiplicity
    )
    connector = Ea::Model::DiagramConnector.new(
      id: "dc1", relationship_ref: association.id,
      connector_type: "Association", source_stereotype: stereotype,
      waypoints: waypoints.map do |x, y|
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
      end,
      label_boxes: label_boxes
    )
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [Ea::Model::Klass.new(id: "c1", name: "A"),
                    Ea::Model::Klass.new(id: "c2", name: "B")],
      relationships: [association],
      diagrams: [Ea::Model::Diagram.new(id: "d1", name: "D",
                                        connectors: [connector])]
    )
  end

  def source_texts(record, **overrides)
    label_seat_positions(
      **record.slice(:waypoints, :label_boxes, :role, :multiplicity),
      stereotype: "property", **overrides
    ).each_with_object({}) { |(text, xy), seen| seen[text] ||= xy }
  end

  def in_reference_space(point, record)
    [point[0] + record[:shift][0], point[1] + record[:shift][1]]
  end
end
