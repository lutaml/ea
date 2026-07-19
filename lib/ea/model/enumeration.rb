# frozen_string_literal: true

module Ea
  module Model
    class Enumeration < Classifier
      attribute :model_kind, :string, default: -> { "enumeration" }
      attribute :literals, EnumerationLiteral, collection: true,
                                               initialize_empty: true

      json do
        map "literals", to: :literals, render_empty: true
      end
    end
  end
end
