# frozen_string_literal: true

# frozen_string: true

module Ea
  module Model
    # A "ghost" classifier name rendered near a connector endpoint
    # that references a classifier NOT placed on the current diagram.
    # EA shows the name as italic text at the connector's off-canvas
    # end so the reader knows what the connector attaches to.
    #
    # Carries:
    #   - name: the classifier's display name (simple or qualified)
    #   - end_kind: :source or :target (which end is ghost)
    #   - anchor: [x, y] canvas-space coordinates of the label
    #
    # Multiple connectors can reference the same ghost classifier;
    # each produces its own GhostLabel at its own anchor.
    class GhostLabel < Base
      attribute :name, :string
      attribute :end_kind, :string
      attribute :anchor_x, :integer
      attribute :anchor_y, :integer

      json do
        map "id", to: :id
        map "name", to: :name
        map "endKind", to: :end_kind
        map "anchorX", to: :anchor_x
        map "anchorY", to: :anchor_y
      end
    end
  end
end
