# frozen_string_literal: true

module ConnectorRedockHelpers
  # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  def redock_fixture(options = {})
    type = options.fetch(:type, "Generalization")
    relation = if type == "Generalization"
                 Ea::Model::Generalization.new(id: "r", specific_id: "s", general_id: "t")
               else
                 Ea::Model::Association.new(id: "r", source_id: "s", target_id: "t")
               end
    width = options.fetch(:width, "2")
    connector = Ea::Model::DiagramConnector.new(
      id: "c", relationship_ref: "r", connector_type: type,
      direction: "Source -> Destination", style: width ? { lwidth: width } : {},
      waypoints: options.fetch(:points, [[20, 100], [20, 40]]).map do |x, y|
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
      end
    )
    anchors = options.fetch(:anchors, [[20, 120], [20, 20]])
    connector.source_anchor, connector.target_anchor = Array(anchors).map do |point|
      redock_point(point)
    end
    rectangles = { "s" => options.fetch(:source, [0, 100, 40, 40]),
                   "t" => options.fetch(:target, [0, 0, 40, 40]) }
    bounds = rectangles.transform_values do |rect|
      rect && Ea::Model::Bounds.new(x: rect[0], y: rect[1], width: rect[2], height: rect[3])
    end
    { diagram: Ea::Model::Diagram.new(id: "d", connectors: [connector]),
      model_index: { "r" => relation }, drawn_bounds: bounds,
      divider_y_by_ref: options[:dividers] }
  end
  # rubocop:enable Metrics/AbcSize,Metrics/MethodLength

  def redock_point(coordinates)
    coordinates && Ea::Model::Point.new(x: coordinates[0], y: coordinates[1])
  end

  def redock_output(fixture)
    diagram = fixture.fetch(:diagram)
    arguments = fixture.reject { |key, _| key == :diagram }
    [Ea::Svg::EaEmitter::Connectors, Ea::Svg::EaEmitter::Markers].map do |renderer|
      svg = renderer.new(diagram, **arguments).render
      Nokogiri::XML(svg).css("path, polygon").map { |node| node["d"] || node["points"] }
    end
  end
end
