# frozen_string_literal: true

module Ea
  module Model
    # UML Signal: a classifier whose instances represent
    # asynchronous communications between objects. Distinct from
    # Klass because EA renders its header with the «signal»
    # stereotype fallback and supports a separate "receptions"
    # compartment.
    class Signal < Classifier
      attribute :model_kind, :string, default: -> { "signal" }
    end
  end
end
