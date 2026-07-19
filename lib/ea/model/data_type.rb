# frozen_string_literal: true

module Ea
  module Model
    class DataType < Classifier
      attribute :model_kind, :string, default: -> { "data_type" }
    end
  end
end
