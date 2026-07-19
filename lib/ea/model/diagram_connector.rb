# frozen_string_literal: true

module Ea
  module Model
    # A connector drawn on a diagram between two DiagramElements.
    # References the underlying Relationship (by id) and the source
    # and target DiagramElements (by id). Carries ordered waypoints
    # for routing.
    class DiagramConnector < Base
      attribute :diagram_id, :string
      attribute :relationship_ref, :string
      attribute :source_element_ref, :string
      attribute :target_element_ref, :string
      attribute :waypoints, Waypoint, collection: true, initialize_empty: true
      attribute :label, :string
      attribute :style, :hash, default: -> { {} }

      json do
        map "id", to: :id
        map "diagramId", to: :diagram_id
        map "relationshipRef", to: :relationship_ref
        map "sourceElementRef", to: :source_element_ref
        map "targetElementRef", to: :target_element_ref
        map "waypoints", to: :waypoints, render_empty: true
        map "label", to: :label
        map "style", to: :style
      end
    end
  end
end
