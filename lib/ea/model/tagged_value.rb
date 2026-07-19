# frozen_string_literal: true

module Ea
  module Model
    # A tagged value: key/value metadata attached to a model element.
    # Optionally scoped to a Stereotype application via
    # `stereotype_ref`.
    class TaggedValue < Base
      attribute :key, :string
      attribute :value, :string
      attribute :stereotype_ref, :string

      json do
        map "key", to: :key
        map "value", to: :value
        map "stereotypeRef", to: :stereotype_ref
      end
    end
  end
end
