# frozen_string_literal: true

module Ea
  module Model
    # A diagram: an ordered set of placed elements and connectors.
    # The diagram references the package it belongs to (by id) and
    # owns its elements/connectors compositionally.
    class Diagram < Base
      attribute :package_id, :string
      attribute :diagram_type, :string  # logical|class|sequence|use_case|...
      attribute :bounds, Bounds         # canvas size
      attribute :elements, DiagramElement, collection: true, initialize_empty: true
      attribute :connectors, DiagramConnector, collection: true, initialize_empty: true
      attribute :annotations, Annotation, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "packageId", to: :package_id
        map "diagramType", to: :diagram_type
        map "bounds", to: :bounds
        map "elements", to: :elements, render_empty: true
        map "connectors", to: :connectors, render_empty: true
        map "annotations", to: :annotations, render_empty: true
      end
    end
  end
end
