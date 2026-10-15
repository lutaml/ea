# frozen_string_literal: true

# Renders one association connector's end labels through
# Ea::Svg::EaEmitter::Labels with data and stereotypes at either end and
# returns [content, [x, y]] pairs in document order (source end first).
module LabelPresenceHelpers
  PRESENCE_WAYPOINTS = [[100, 200], [300, 200]].freeze

  # ends: { source: { role:, mult:, stereotype: }, target: { ... } }
  def label_presence_texts(ends:, label_boxes:,
                           waypoints: PRESENCE_WAYPOINTS)
    document = label_presence_document(ends, label_boxes, waypoints)
    labels = Ea::Svg::EaEmitter::Labels.new(
      document.diagrams.first,
      model_index: document.index_by_id, document: document
    )
    Nokogiri::XML(%(<svg>#{labels.render}</svg>)).css("text").map do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end

  def label_presence_contents(texts)
    texts.map(&:first)
  end

  def label_presence_document(ends, label_boxes, waypoints)
    source = ends.fetch(:source, {})
    target = ends.fetch(:target, {})
    association = Ea::Model::Association.new(
      id: "r1", source_id: "c1", target_id: "c2",
      source_role_name: source[:role], source_multiplicity_raw: source[:mult],
      target_role_name: target[:role], target_multiplicity_raw: target[:mult]
    )
    connector = Ea::Model::DiagramConnector.new(
      id: "dc1", relationship_ref: association.id,
      connector_type: "Association",
      source_stereotype: source[:stereotype],
      target_stereotype: target[:stereotype],
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
end
