# frozen_string_literal: true

module LabelHeadingHelpers
  def build_heading_connector(record)
    Ea::Model::DiagramConnector.new(
      id: "heading", relationship_ref: "heading", connector_type: "Aggregation",
      source_stereotype: "property", style: { mode: "3", lwidth: "2" },
      source_anchor: heading_point(record[:anchors][0]),
      target_anchor: heading_point(record[:anchors][1]),
      waypoints: record[:points].map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) },
      label_boxes: heading_label_boxes(record)
    )
  end

  def heading_label_boxes(record)
    { llt: record[:box].transform_keys(&:to_s),
      llb: record.fetch(:mult_box, { "ox" => 10, "oy" => -2, "alignment" => 1 }).transform_keys(&:to_s),
      lrt: { "ox" => 5, "oy" => 7 } }
  end

  def heading_bounds_for(record)
    %i[source target].to_h do |name|
      x, y, width, height = record[name]
      [name.to_s, Ea::Model::Bounds.new(x: x, y: y, width: width, height: height)]
    end
  end

  def heading_point(coordinates)
    Ea::Model::Point.new(x: coordinates[0], y: coordinates[1])
  end

  def heading_relationship(role, mult)
    Ea::Model::Association.new(
      id: "heading", source_id: "source", target_id: "target",
      source_role_name: role, source_multiplicity_raw: mult,
      target_role_name: "owner"
    )
  end

  def heading_positions(connector, bounds, role: "trafficAreaStructureAttribute", mult: "0..1")
    diagram = Ea::Model::Diagram.new(id: "d", connectors: [connector])
    labels = Ea::Svg::EaEmitter::Labels.new(
      diagram, model_index: { "heading" => heading_relationship(role, mult) }, drawn_bounds: bounds,
               theme: Ea::Theme::Definition.new(id: "headings", font_family: "Cambria", font_size: 7)
    )
    Nokogiri::XML("<svg>#{labels.render}</svg>").css("text").to_h do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end

  def clipped_target_connector(stored_target_y)
    build_heading_connector(
      points: [[984, 188], [876, stored_target_y]],
      anchors: [[1044, 190], [788, 194]],
      box: { "ox" => 5, "oy" => 7, "alignment" => 1 }
    )
  end
end
