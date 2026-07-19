# frozen_string_literal: true

module Ea
  module Model
    # A single waypoint on a DiagramConnector's path. Connectors
    # route between source and target diagram elements through zero
    # or more waypoints; the source adapter parses the EA `SeqNo`
    # packed list into ordered Waypoints.
    class Waypoint < Base
      attribute :position, Point
      attribute :routing, :string, default: -> { "line" }

      json do
        map "position", to: :position
        map "routing", to: :routing
      end
    end
  end
end
