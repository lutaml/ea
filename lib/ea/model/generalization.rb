# frozen_string_literal: true

module Ea
  module Model
    # Generalization (inheritance): specific (child) extends
    # general (parent).
    class Generalization < Relationship
      attribute :specific_id, :string  # child
      attribute :general_id, :string   # parent

      attribute :relationship_kind, :string, default: -> { "generalization" }

      json do
        map "specificId", to: :specific_id
        map "generalId", to: :general_id
      end
    end
  end
end
