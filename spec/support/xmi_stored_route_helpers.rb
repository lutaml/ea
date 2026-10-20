# frozen_string_literal: true

module XmiStoredRouteHelpers
  def stored_route_for(style, connector_type, bends: [])
    box = Ea::Model::Bounds.new(x: 0, y: 0, width: 100, height: 50)
    Ea::Sources::Xmi::StoredRoute.new.waypoints(
      link: Ea::Sources::Xmi::StoredRoute::Link.new(style, "", ""), connector_type: connector_type,
      source: box, target: box, bends: bends, offsets: { source: [nil, nil], target: [nil, nil] }
    )
  end
end
