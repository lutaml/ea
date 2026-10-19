# frozen_string_literal: true

# GUID-joined QEA/XMI and native SVG controls from Plateau diagram 199.
# Coordinates are content coordinates, independently aligned by owner rectangles.
module LabelSourceStairHelpers
  def source_stair_records
    [
      { role: "ifcBuildingFurnitureAttribute", target_x: 221, width: 170,
        offsets: [[-223, 38], [-33, -10]], expected: [[174, 366], [504, 318]] },
      { role: "ifcBuildingStoreyAttribute", target_x: 656, width: 156,
        offsets: [[213, 49], [-61, -10]], expected: [[625, 377], [476, 318]] }
    ]
  end

  def source_stair_connector(record)
    points = [[534, 310], [534, 400], [record[:target_x], 400], [record[:target_x], 450]]
    boxes = record[:offsets].zip([record[:width], 19]).map do |(ox, oy), cx|
      { "ox" => ox, "oy" => oy, "cx" => cx, "cy" => 18, "alignment" => 1 }
    end
    Ea::Model::DiagramConnector.new(
      id: "stair", relationship_ref: "stair", connector_type: "Aggregation",
      style: { mode: "3", lwidth: "0", tree: "V" },
      waypoints: points.map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) },
      label_boxes: { llt: boxes[0], llb: boxes[1] }
    )
  end

  def source_stair_positions(connector, record, family: "Cambria", target: false)
    labels = Ea::Svg::EaEmitter::Labels.new(
      Ea::Model::Diagram.new(id: "d", connectors: [connector]),
      model_index: { "stair" => source_stair_association(record, target) },
      theme: Ea::Theme::Definition.new(id: "stair", font_family: family, font_size: 7)
    )
    Nokogiri::XML("<svg>#{labels.render}</svg>").css("text").to_h do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end

  def source_stair_association(record, target)
    attributes = if target
                   { target_role_name: record[:role], target_multiplicity_raw: "0..*" }
                 else
                   { source_role_name: record[:role], source_multiplicity_raw: "0..*" }
                 end
    Ea::Model::Association.new(id: "stair", source_id: "s", target_id: "t", **attributes)
  end
end
