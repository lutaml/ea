# frozen_string_literal: true

module Ea
  module Model
    # A UML/OCL constraint attached to a classifier or other model
    # element. EA stores these in t_objectconstraint; the `name` is
    # the constraint label (rendered as "{name}" in the constraints
    # compartment), and the body holds the OCL expression.
    class Constraint < Base
      attribute :name, :string
      attribute :kind, :string # "OCL", "Invariant", "Postcondition", etc.
      attribute :body, :string
      attribute :status, :string

      json do
        map "id", to: :id
        map "name", to: :name
        map "kind", to: :kind
        map "body", to: :body
        map "status", to: :status
      end
    end
  end
end
