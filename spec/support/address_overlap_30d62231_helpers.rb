# frozen_string_literal: true

module AddressOverlap30D62231Support
  CONNECTOR_ID = "EAID_274C13E6_6F94_49ae_8E13_1174894320DF"
  PROPERTY_ID = "EAID_src4C13E6_6F94_49ae_8E13_1174894320DF"

  def address_fixture_path
    fixtures_path("address_overlap_30d62231.xmi")
  end

  def address_route_metadata(style: {}, offsets: { source: [8, 12], target: [16, 12] }, path: "", edge: 4)
    connector = address_connector(style)
    bounds = { source: Ea::Model::Bounds.new(x: 1172, y: 413, width: 120, height: 80),
               target: Ea::Model::Bounds.new(x: 815, y: 444, width: 235, height: 156) }
    link = Ea::Sources::Xmi::StoredRoute::Link.new("Mode=2;LWidth=0;", path)
    Ea::Sources::Xmi::StoredRoute.new.association_route(
      connector, link: link, bounds: bounds, offsets: offsets, edge: edge
    )
  end

  def address_connector(style)
    Ea::Model::DiagramConnector.new(
      connector_type: "Association", style: { mode: "2", lwidth: "0", umldi_route: true }.merge(style),
      waypoints: [[1171, 458], [1051, 458]].map do |x, y|
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
      end
    )
  end
end
