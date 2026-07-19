# frozen_string_literal: true

module Ea
  module Model
    class PrimitiveType < Classifier
      attribute :model_kind, :string, default: -> { "primitive_type" }
    end
  end
end
