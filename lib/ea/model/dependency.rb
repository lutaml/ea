# frozen_string_literal: true

module Ea
  module Model
    # Dependency: client depends on supplier. No semantic
    # implication beyond "client references supplier".
    class Dependency < Relationship
      attribute :client_id, :string
      attribute :supplier_id, :string

      attribute :relationship_kind, :string, default: -> { "dependency" }

      json do
        map "clientId", to: :client_id
        map "supplierId", to: :supplier_id
      end
    end
  end
end
