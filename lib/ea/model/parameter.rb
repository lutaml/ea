# frozen_string_literal: true

module Ea
  module Model
    # A single parameter of an Operation.
    class Parameter < Base
      attribute :ordinal, :integer
      attribute :direction, :string, default: -> { "in" } # in|out|inout|return
      attribute :type_name, :string
      attribute :multiplicity_lower, :integer
      attribute :multiplicity_upper, :integer
      attribute :default_value, :string

      json do
        map "ordinal", to: :ordinal
        map "direction", to: :direction
        map "typeName", to: :type_name
        map "multiplicityLower", to: :multiplicity_lower
        map "multiplicityUpper", to: :multiplicity_upper
        map "defaultValue", to: :default_value
      end
    end
  end
end
