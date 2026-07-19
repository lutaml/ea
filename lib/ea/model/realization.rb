# frozen_string_literal: true

module Ea
  module Model
    # Realization: a classifier implements the contract defined by
    # an interface.
    class Realization < Relationship
      attribute :realizing_id, :string
      attribute :contract_id, :string

      attribute :relationship_kind, :string, default: -> { "realization" }

      json do
        map "realizingId", to: :realizing_id
        map "contractId", to: :contract_id
      end
    end
  end
end
