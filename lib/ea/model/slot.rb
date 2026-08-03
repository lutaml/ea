# frozen_string_literal: true

module Ea
  module Model
    # A single slot (variable = value) on an InstanceSpecification.
    class Slot < Base
      attribute :name, :string
      attribute :value, :string
      attribute :op, :string, default: -> { "=" }

      json do
        map "id", to: :id
        map "name", to: :name
        map "value", to: :value
        map "op", to: :op
      end
    end
  end
end
