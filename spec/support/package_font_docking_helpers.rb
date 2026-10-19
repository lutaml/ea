# frozen_string_literal: true

module PackageFontDockingHelpers
  def font_docking_fixture(points = [[120, 40], [300, 40]])
    relation = Ea::Model::Association.new(id: "r", source_id: "s", target_id: "t")
    index = { "s" => Ea::Model::Package.new(id: "s", name: "uro", stereotype_refs: ["ApplicationSchema"]),
              "t" => Ea::Model::Package.new(id: "t", name: "core"), "r" => relation }
    connector = Ea::Model::DiagramConnector.new(
      relationship_ref: "r", connector_type: "Association", style: { direct: true, lwidth: "0" },
      waypoints: points.map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) }
    )
    diagram = Ea::Model::Diagram.new(elements: [font_docking_package("s", 0, 80),
                                                font_docking_package("t", 300, 120)], connectors: [connector])
    [diagram, index]
  end

  def font_docking_package(ref, x_position, width)
    Ea::Model::DiagramElement.new(
      model_element_ref: ref, font_family: "Cambria", font_size: 7, font_size_unit: "pt",
      bounds: Ea::Model::Bounds.new(x: x_position, y: 0, width: width, height: 80)
    )
  end

  def font_docking_path(diagram, index, bounds = nil)
    svg = Ea::Svg::EaEmitter::Connectors.new(diagram, model_index: index, drawn_bounds: bounds).render
    Nokogiri::XML(svg).at_css("path")["d"]
  end
end
