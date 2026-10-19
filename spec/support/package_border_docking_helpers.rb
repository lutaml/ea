# frozen_string_literal: true

module PackageBorderDockingHelpers
  def package_border_emitters(document)
    diagram = document.diagrams.find { |entry| entry.id == "DFBB1072-8EC5-4384-8241-7EDF4B6B888B" }
    options = package_border_options(diagram, document.index_by_id)
    [diagram, Ea::Svg::EaEmitter::Connectors.new(diagram, **options),
     Ea::Svg::EaEmitter::Markers.new(diagram, **options)]
  end

  def package_border_options(diagram, index)
    canvas = Ea::Svg::EaEmitter::Canvas.from(diagram, model_index: index)
    layers = Ea::Svg::EaEmitter::LayerSequencer.new(diagram, canvas: canvas, model_index: index)
    layers.send(:element_layers)
    { canvas: canvas, model_index: index, drawn_bounds: layers.drawn_bounds,
      divider_y_by_ref: layers.divider_y_by_ref }
  end

  def package_border_geometry(emitters, ref)
    diagram, routes, markers = emitters
    connector = diagram.connectors.find { |entry| entry.relationship_ref == ref }
    route = Nokogiri::XML(routes.send(:path_for, connector)).at_css("path")["d"]
    arrowheads = markers.send(:entries_for, connector).map do |entry|
      Nokogiri::XML(entry.body).at_css("path")["d"]
    end
    [route, *arrowheads]
  end
end
