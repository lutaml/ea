# frozen_string_literal: true

module Ea
  module Model
    # Abstract base for typed relationships between classifiers.
    # Concrete subclasses: Association, Generalization, Realization,
    # Dependency. The discriminator (`relationship_kind`) lets
    # consumers dispatch without `is_a?` ladders.
    class Relationship < Base
      attribute :qualified_name, :string
      attribute :relationship_kind, :string, default: -> { "relationship" }

      json do
        map "id", to: :id
        map "name", to: :name
        map "qualifiedName", to: :qualified_name
        map "relationshipKind", to: :relationship_kind, render_default: true
      end
    end
  end
end
