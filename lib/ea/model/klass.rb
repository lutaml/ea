# frozen_string_literal: true

module Ea
  module Model
    # Named `Klass` (not `Class`) to avoid collision with Ruby's
    # built-in Class. Represents a UML Class.
    class Klass < Classifier
      attribute :model_kind, :string, default: -> { "class" }
      attribute :is_active, :boolean, default: false

      json do
        map "isActive", to: :is_active, render_default: true
      end
    end
  end
end
