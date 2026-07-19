# frozen_string_literal: true

module Ea
  module Model
    # A Stereotype declaration. Stereotypes carry a name, optional
    # profile, and may declare a schema of tagged-value keys.
    #
    # A classifier/property/operation "has" a stereotype by
    # reference (stereotype_ref on the element or its tagged values).
    class Stereotype < Base
      attribute :qualified_name, :string
      attribute :profile, :string
      attribute :declared_tagged_value_keys, :string, collection: true,
                                                      initialize_empty: true

      json do
        map "qualifiedName", to: :qualified_name
        map "profile", to: :profile
        map "declaredTaggedValueKeys", to: :declared_tagged_value_keys,
                                       render_empty: true
      end
    end
  end
end
