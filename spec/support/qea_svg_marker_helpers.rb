# frozen_string_literal: true

module QeaMarkerHelpers
  include QeaRoutingHelpers

  def diamond_layers(connector_type:, **connector_attributes)
    layers = nil
    render_qea_route(path: "M 300,350 L 400,350", style: "",
                     source: [100, 300, 200, 100], target: [400, 300, 200, 100],
                     connector_type: connector_type,
                     connector_attributes: connector_attributes) do |document|
      layers = Ea::Svg::EaEmitter::Markers.new(
        document.diagrams.first, model_index: document.index_by_id
      ).layers
    end
    layers
  end

  def diamond_geometry(connector_type:, **connector_attributes)
    geometry = nil
    render_qea_route(path: "M 300,350 L 400,350", style: "",
                     source: [100, 300, 200, 100], target: [400, 300, 200, 100],
                     connector_type: connector_type,
                     connector_attributes: connector_attributes) do |document|
      diagram = document.diagrams.first
      index = document.index_by_id
      markers = Nokogiri::XML("<svg>#{Ea::Svg::EaEmitter::Markers.new(diagram, model_index: index).render}</svg>")
      line = Ea::Svg::EaEmitter::Connectors.new(diagram, model_index: index).render
      ends = line.scan(/-?\d+ -?\d+/).map { |pair| pair.split.map(&:to_i) }
      geometry = { tip: markers.at_xpath("//polygon")["points"].split.first(2).map(&:to_i),
                   start: ends.first, finish: ends.last,
                   arrows: markers.xpath("//path").size,
                   keys: markers.xpath("//g").map { |g| g["style"][/fill:(#\h+)/, 1] } }
    end
    geometry
  end

  def pen_widths(style)
    widths = {}
    render_qea_route(path: "M 300,350 L 400,350", style: style,
                     source: [100, 300, 200, 100], target: [400, 300, 200, 100],
                     connector_type: "Generalization") do |document|
      diagram = document.diagrams.first
      index = document.index_by_id
      widths[:line] = stroke_widths(Ea::Svg::EaEmitter::Connectors.new(diagram, model_index: index).layers)
      widths[:marker] = stroke_widths(Ea::Svg::EaEmitter::Markers.new(diagram, model_index: index).layers)
    end
    widths
  end

  def stroke_widths(layers)
    layers.map { |layer| layer.style[/stroke-width:(\d+)/, 1].to_i }
  end

  def nesting_markup(direction)
    markup = nil
    line = nil
    render_qea_route(path: "M 300,350 L 400,350", style: "Mode=3;TREE=LV;",
                     source: [100, 300, 200, 100], target: [400, 300, 200, 100],
                     connector_type: "Nesting",
                     connector_attributes: { direction: direction }) do |document|
      diagram = document.diagrams.first
      markup = Nokogiri::XML(
        "<svg>#{Ea::Svg::EaEmitter::Markers.new(diagram, model_index: document.index_by_id).render}</svg>"
      )
      line = Ea::Svg::EaEmitter::Connectors.new(diagram, model_index: document.index_by_id).render
    end
    [markup, line.scan(/-?\d+(?:\.\d+)? -?\d+(?:\.\d+)?/).map { |pair| pair.split.map(&:to_f) }]
  end

  def specs(connector_type, direction = "Source -> Destination", relationship: nil)
    connector = Ea::Model::DiagramConnector.new(
      id: "dc",
      connector_type: connector_type,
      direction: direction,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
    described_class.specs_for(connector, connector_type,
                              [0, 0], [100, 0], [0, 0], [100, 0],
                              relationship: relationship)
  end

  def make_context(classifier)
    Struct.new(:classifier, :bounds, :canvas).new(classifier, bounds, nil)
  end
end
