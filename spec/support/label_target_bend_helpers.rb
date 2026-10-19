# frozen_string_literal: true

# GUID-joined QEA/XMI paths and labels from Plateau diagram 32, translated
# from native SVG by (+30,+70). The three routes have unchanged saved knots.
module LabelTargetBendHelpers
  def target_bend_records
    [
      { role: "lod4MultiSolid", points: [[873, 518], [873, 670], [876, 670], [876, 720]],
        offsets: [[116, -23], [104, -23]], width: 70, expected: [[910, 644], [985, 644]] },
      { role: "lod4MultiSurface", points: [[752, 518], [752, 670], [686, 670], [686, 720]],
        offsets: [[-110, -13], [-113, -13]], width: 82, expected: [[553, 654], [647, 654]] },
      { role: "lod4ImplicitRepresentation", points: [[250, 530], [250, 660], [217, 660], [217, 710]],
        offsets: [[-79, -30], [-125, -19]], width: 135, expected: [[38, 627], [133, 638]] }
    ]
  end

  def target_bend_connector(record)
    Ea::Model::DiagramConnector.new(
      id: "bend", relationship_ref: "bend", connector_type: "Association",
      style: { mode: "3", lwidth: "0", tree: "V" },
      waypoints: record[:points].map do |x, y|
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
      end,
      label_boxes: target_bend_boxes(record)
    )
  end

  def target_bend_boxes(record)
    boxes = record[:offsets].zip([record[:width], 19], [31, 16]).map do |(ox, oy), cx, cy|
      { "ox" => ox, "oy" => oy, "cx" => cx, "cy" => cy, "alignment" => 1 }
    end
    { lrt: boxes[0], lrb: boxes[1] }
  end

  def target_bend_association(role, source)
    attributes = if source
                   { source_role_name: role, source_multiplicity_raw: "0..1" }
                 else
                   { target_role_name: role, target_multiplicity_raw: "0..1" }
                 end
    Ea::Model::Association.new(id: "bend", source_id: "s", target_id: "t", **attributes)
  end

  def target_bend_positions(connector, role, source: false, family: "Cambria")
    labels = Ea::Svg::EaEmitter::Labels.new(
      Ea::Model::Diagram.new(id: "d", connectors: [connector]),
      model_index: { "bend" => target_bend_association(role, source) },
      theme: Ea::Theme::Definition.new(id: "bend", font_family: family, font_size: 7)
    )
    Nokogiri::XML("<svg>#{labels.render}</svg>").css("text").to_h do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end
end
