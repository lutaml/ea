# frozen_string_literal: true

module Ea
  module Model
    # A connector drawn on a diagram between two DiagramElements.
    # References the underlying Relationship (by id) and the source
    # and target DiagramElements (by id). Carries ordered waypoints
    # for routing plus the EA EDGE codes (1=top, 2=right, 3=bottom,
    # 4=left, 5..8=diagonal variants) which tell the renderer where
    # to anchor the line on each end.
    class DiagramConnector < Base
      attribute :diagram_id, :string
      attribute :relationship_ref, :string
      attribute :source_element_ref, :string
      attribute :target_element_ref, :string
      attribute :source_duid, :string
      attribute :target_duid, :string
      attribute :source_edge, :integer
      attribute :target_edge, :integer
      attribute :waypoints, Waypoint, collection: true, initialize_empty: true
      attribute :label, :string
      attribute :style, :hash, default: -> { {} }
      attribute :line_color, :integer
      attribute :line_width, :integer
      attribute :hidden, :boolean
      attribute :label_boxes, :hash, default: -> { {} }

      json do
        map "id", to: :id
        map "diagramId", to: :diagram_id
        map "relationshipRef", to: :relationship_ref
        map "sourceElementRef", to: :source_element_ref
        map "targetElementRef", to: :target_element_ref
        map "sourceDuid", to: :source_duid
        map "targetDuid", to: :target_duid
        map "sourceEdge", to: :source_edge
        map "targetEdge", to: :target_edge
        map "waypoints", to: :waypoints, render_empty: true
        map "label", to: :label
        map "style", to: :style
        map "lineColor", to: :line_color
        map "lineWidth", to: :line_width
        map "hidden", to: :hidden, render_default: true
        map "labelBoxes", to: :label_boxes
      end
    end
  end
end
