# frozen_string_literal: true

module ConnectorBridgesHelpers
  def bridge_connector(id, points, **attributes)
    Ea::Model::DiagramConnector.new(
      id: id, source_element_ref: "owner-#{id}",
      waypoints: points.map do |x, y|
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
      end, **attributes
    )
  end

  def bridge_diagram(connectors, orders = [25, 9, 21])
    Ea::Model::Diagram.new(
      id: "bridges", connectors: connectors,
      elements: connectors.each_with_index.map do |connector, index|
        Ea::Model::DiagramElement.new(
          id: "owner-#{connector.id}", z_order: orders[index],
          model_element_ref: "model-#{connector.id}"
        )
      end
    )
  end

  def bridge_paths(diagram, **options)
    output = Ea::Svg::EaEmitter::Connectors.new(diagram, **options).render
    xml = Nokogiri::XML("<svg>#{output}</svg>")
    xml.xpath("//path").map { |path| path["d"] }
  end
end

module ConnectorBridgesHelpers
  def bridge_resolved_fixture
    winner = bridge_connector("a", [[0, 0], [0, 100]], relationship_ref: "vertical")
    partner = bridge_connector("b", [[0, 150], [100, 150]], relationship_ref: "horizontal")
    bounds = bridge_resolved_bounds
    relationships = { "vertical" => Ea::Model::Generalization.new(specific_id: "v1", general_id: "v2"),
                      "horizontal" => Ea::Model::Generalization.new(specific_id: "h1", general_id: "h2") }
    [bridge_diagram([winner, partner]), { drawn_bounds: bounds, model_index: relationships,
                                          divider_y_by_ref: { "v1" => -100, "v2" => -100,
                                                              "h1" => 50, "h2" => 50 } }]
  end

  def bridge_resolved_bounds
    bounds = { "v1" => [40, 0, 20, 10], "v2" => [40, 90, 20, 10],
               "h1" => [0, 40, 10, 20], "h2" => [90, 40, 10, 20] }
    bounds.transform_values do |x, y, width, height|
      Ea::Model::Bounds.new(x: x, y: y, width: width, height: height)
    end
  end
end
