# frozen_string_literal: true

module SemanticConnectorDashHelpers
  def dash_connector(type, stereotype: nil, width: nil)
    id = "#{type}-#{stereotype}-#{width}"
    connector = Ea::Model::DiagramConnector.new(
      id: id, relationship_ref: id, connector_type: type,
      style: { direct: true, lwidth: width, linestyle: "3" },
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
    [connector, Ea::Model::Relationship.new(id: id, stereotype: stereotype)]
  end

  def dash_layers(records, grouped: true)
    diagram = Ea::Model::Diagram.new(id: "d", connectors: records.map(&:first))
    index = records.to_h { |connector, relationship| [connector.relationship_ref, relationship] }
    Ea::Svg::EaEmitter::Connectors.new(diagram, model_index: index, grouped: grouped).layers
  end
end
