# frozen_string_literal: true

module Ea
  module Model
    # A single literal of an Enumeration.
    class EnumerationLiteral < Base
      attribute :value, :string
      attribute :ordinal, :integer

      json do
        map "value", to: :value
        map "ordinal", to: :ordinal
      end
    end
  end
end
