# frozen_string_literal: true

module QeaGrownRayHelpers
  def grown_ray_pairs(drawn_source:, **route)
    document = grown_ray_document(route)
    diagram = document.diagrams.first
    boxes = [drawn_source, route[:target]].map do |x, y, width, height|
      Ea::Model::Bounds.new(x: x, y: y, width: width, height: height)
    end
    bounds = diagram.elements.map(&:model_element_ref).zip(boxes).to_h
    Ea::Svg::EaEmitter::ConnectorRedock.pairs_for(diagram.connectors.first, diagram,
                                                  document.index_by_id, bounds)
  end

  def grown_ray_document(route)
    document = nil
    render_qea_route(**route, path: route[:path],
                              object_styles: ["LWth=2;", "LWth=2;"]) { |built| document = built }
    document
  end
end
