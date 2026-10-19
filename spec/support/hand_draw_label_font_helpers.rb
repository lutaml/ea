# frozen_string_literal: true

module HandDrawLabelFontHelpers
  def hand_draw_label_styles(document, theme:)
    svg = Ea::Svg::EaEmitter::Labels.new(document.diagrams.first, model_index: document.index_by_id,
                                                                  theme: theme).render
    Nokogiri::XML("<svg>#{svg}</svg>").css("text").map { |node| node["style"] }
  end

  def hand_draw_label_properties
    [Ea::Model::Property.new(id: "p_src", name: "items", owner_id: "c1",
                             visibility: "public", multiplicity_lower: 0, multiplicity_upper: -1),
     Ea::Model::Property.new(id: "p_tgt", name: "owner", owner_id: "c2",
                             visibility: "public", multiplicity_lower: 0, multiplicity_upper: 1)]
  end

  def hand_draw_label_connector
    Ea::Model::DiagramConnector.new(id: "dc1", relationship_ref: "r1", waypoints: [
                                      Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
                                      Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
                                    ])
  end

  def hand_draw_label_document(hand_draw:)
    source, target = hand_draw_label_properties
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [Ea::Model::Klass.new(id: "c1", name: "A", properties: [source]),
                    Ea::Model::Klass.new(id: "c2", name: "B", properties: [target])],
      relationships: [Ea::Model::Association.new(id: "r1", name: "Relationship One",
                                                 source_id: source.id, target_id: target.id)],
      diagrams: [Ea::Model::Diagram.new(id: "d1", name: "D", hand_draw: hand_draw,
                                        connectors: [hand_draw_label_connector])]
    )
  end
end
