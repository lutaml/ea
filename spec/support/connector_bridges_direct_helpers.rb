# frozen_string_literal: true

# Builds connectors and bridged paths for the target-first direct-line examples.
module ConnectorBridgesDirectHelpers
  def bridge_connector(type, order, source, style = {})
    Ea::Model::DiagramConnector.new(connector_type: type, paint_order: order, source_element_ref: source, style: style)
  end

  # Path of `carrier` along `geometry` when `partner` crosses it at right angles.
  def bridged_path(carrier, geometry, partner: nil)
    crossings = [[carrier, geometry]]
    crossings << [partner, [[100, 0], [100, 100]]] if partner
    Ea::Svg::EaEmitter.const_get(:ConnectorBridges).new(nil, crossings).path_for(carrier, geometry)
  end
end
