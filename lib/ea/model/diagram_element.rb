# frozen_string_literal: true

module Ea
  module Model
    # A single placed element on a diagram. References the model
    # element it visualizes (by id), carries pixel bounds and a
    # parsed style map (fill color, line color, font, etc.).
    class DiagramElement < Base
      attribute :diagram_id, :string
      attribute :model_element_ref, :string # id of Classifier/Package/etc.
      attribute :bounds, Bounds
      attribute :style, :hash, default: -> { {} } # parsed style fields

      json do
        map "id", to: :id
        map "diagramId", to: :diagram_id
        map "modelElementRef", to: :model_element_ref
        map "bounds", to: :bounds
        map "style", to: :style
      end
    end
  end
end
