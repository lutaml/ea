# frozen_string_literal: true

module AggregationPartialPort09AF6B8ASupport
  CONNECTOR_ID = "EAID_16B6E623_A3B1_40c4_968A_D2C35D1139B3"
  PROPERTY_ID = "EAID_srcB6E623_A3B1_40c4_968A_D2C35D1139B3"
  FIXTURE = "aggregation_partial_port_09af6b8a.xmi"

  def fixture_path
    fixtures_path(FIXTURE)
  end

  def parsed_document
    Ea::Sources::Xmi::Adapter.from_path(fixture_path)
  end

  def fixture_diagram(document)
    document.diagrams.find { |entry| entry.id.include?("09AF6B8A") }
  end

  def render_xml(document, diagram)
    Nokogiri::XML(Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render)
  end

  def zero_offsets
    { source: [0, 0], target: [0, 0] }
  end

  def both_nonzero_offsets
    { source: [5, 40], target: [3, 12] }
  end

  def route_result(style:, offsets:, path: "1022:-205;1003:-205;", route_flag: false)
    route_style = style.dup
    route_style[:umldi_route] = true if route_flag
    model = Struct.new(:connector_type, :style, :waypoints).new("Aggregation", route_style, route_points)
    link = Ea::Sources::Xmi::StoredRoute::Link.new("Mode=#{style[:mode]};LWidth=2;", path)
    Ea::Sources::Xmi::StoredRoute.new.association_route(
      model, link: link, bounds: route_bounds, offsets: offsets, edge: 1
    )
  end

  private

  def route_bounds
    box = Ea::Model::Bounds
    {
      source: box.new(x: 899, y: 380, width: 220, height: 88),
      target: box.new(x: 875, y: 84, width: 270, height: 71)
    }
  end

  def route_points
    [[1015, 380], [1015, 155]].map { |x, y| Ea::Model::Point.new(x: x, y: y) }
  end
end
