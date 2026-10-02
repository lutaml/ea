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
      attribute :connector_type, :string
      attribute :direction, :string
      # t_connector.SourceStereotype / DestStereotype — EA renders
      # the «Property» end-label exactly on the stereotyped end
      # (corpus-verified; direction alone does not decide).
      attribute :source_stereotype, :string
      attribute :target_stereotype, :string
      attribute :waypoints, Waypoint, collection: true, initialize_empty: true
      attribute :label, :string
      attribute :style, :hash, default: -> { {} }
      attribute :line_color, :integer
      attribute :line_width, :integer
      attribute :hidden, :boolean
      attribute :label_boxes, :hash, default: -> { {} }
      attribute :ghost_labels, GhostLabel, collection: true, initialize_empty: true
      # True when the t_diagramlinks.Geometry string carries explicit
      # SX/SY/EX/EY offset fields. EA renders the «import» package_anchor
      # marker only for connectors with explicit offsets — auto-routed
      # connectors (no SX/SY) get a plain solid line.
      attribute :has_geometry_offsets, :boolean, default: false

      # Absolute connection points on the source/target element boxes,
      # derived from the Geometry SX/SY and EX/EY edge offsets. EA
      # docks the connector's visible endpoints at these ports; nil
      # when the geometry string carries no offsets (auto-routed).
      attribute :source_port, Ea::Model::Point
      attribute :target_port, Ea::Model::Point

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
        map "sourcePort", to: :source_port
        map "targetPort", to: :target_port
        map "connectorType", to: :connector_type
        map "direction", to: :direction
        map "sourceStereotype", to: :source_stereotype
        map "targetStereotype", to: :target_stereotype
        map "waypoints", to: :waypoints, render_empty: true
        map "label", to: :label
        map "style", to: :style
        map "lineColor", to: :line_color
        map "lineWidth", to: :line_width
        map "hidden", to: :hidden, render_default: true
        map "labelBoxes", to: :label_boxes
        map "ghostLabels", to: :ghost_labels, render_empty: true
        map "hasGeometryOffsets", to: :has_geometry_offsets, render_default: true
      end

      # EA encodes package nesting and other implicit relationships
      # as connector rows in t_diagramlinks. These are typically
      # not rendered as paths in the SVG output — the containment
      # is implied by visual position. However, when a connector
      # has the `tree` style attribute (e.g. "V" for vertical tree
      # routing), EA renders it as a real visible connector with
      # a "+" marker at the contained end.
      IMPLICIT_TYPES = %w[Nesting].freeze

      # True when this connector should appear in SVG output. False
      # when hidden via the Hidden flag. Implicit-type connectors
      # (e.g. Nesting) are filtered out UNLESS they carry a `tree`
      # style attribute marking them as visible (basic.qea's
      # "Package Contents" diagram has visible nesting; simple.qea's
      # "Package Contents" diagram has invisible implicit nesting).
      def renderable?
        return false if hidden
        return true unless IMPLICIT_TYPES.include?(connector_type.to_s)

        (style || {}).key?(:tree) || (style || {}).key?("tree")
      end
    end
  end
end
