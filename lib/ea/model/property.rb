# frozen_string_literal: true

module Ea
  module Model
    # A Property is a typed slot on a Classifier (attribute or
    # navigable association end). References its type by id when
    # possible (model-internal), falling back to `type_name` for
    # primitives or external types.
    class Property < Base
      attribute :owner_id, :string              # classifier that owns it
      attribute :type_ref, :string              # id of Classifier (nil if external)
      attribute :type_name, :string             # name shown when type is external/primitive
      attribute :qualified_name, :string
      attribute :multiplicity_lower, :integer
      attribute :multiplicity_upper, :integer   # -1 means "many"
      attribute :default_value, :string
      attribute :is_derived, :boolean, default: false
      attribute :is_readonly, :boolean, default: false
      attribute :is_ordered, :boolean, default: false
      attribute :is_unique, :boolean, default: true
      attribute :aggregation, :string, default: -> { "none" } # none|shared|composite
      attribute :visibility, :string # public|protected|private|package
      attribute :stereotype_refs, :string, collection: true, initialize_empty: true
      attribute :tagged_values, TaggedValue, collection: true, initialize_empty: true
      attribute :annotations, Annotation, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "ownerId", to: :owner_id
        map "typeRef", to: :type_ref
        map "typeName", to: :type_name
        map "qualifiedName", to: :qualified_name
        map "multiplicityLower", to: :multiplicity_lower
        map "multiplicityUpper", to: :multiplicity_upper
        map "defaultValue", to: :default_value
        map "isDerived", to: :is_derived, render_default: true
        map "isReadonly", to: :is_readonly, render_default: true
        map "isOrdered", to: :is_ordered, render_default: true
        map "isUnique", to: :is_unique, render_default: true
        map "aggregation", to: :aggregation, render_default: true
        map "visibility", to: :visibility
        map "stereotypeRefs", to: :stereotype_refs, render_empty: true
        map "taggedValues", to: :tagged_values, render_empty: true
        map "annotations", to: :annotations, render_empty: true
      end
    end
  end
end
