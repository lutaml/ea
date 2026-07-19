# frozen_string_literal: true

module Ea
  module Model
    class Interface < Classifier
      attribute :model_kind, :string, default: -> { "interface" }
    end
  end
end
