# frozen_string_literal: true

module PaintOrderHelpers
  def waypoints(*points)
    points.map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) }
  end

  def placement(ref, z_order, left)
    Ea::Model::DiagramElement.new(
      model_element_ref: ref, z_order: z_order,
      bounds: Ea::Model::Bounds.new(x: left, y: 0, width: 50, height: 40)
    )
  end

  def generalization(ref, paint_order, row)
    Ea::Model::DiagramConnector.new(
      relationship_ref: ref, connector_type: "Generalization", paint_order: paint_order,
      waypoints: waypoints([100, row], [300, row])
    )
  end

  def svg_for(diagram, index)
    Nokogiri::XML(Ea::Svg::EaEmitter::Document.new(diagram, model_index: index, content_anchor: false).render)
  end
end
