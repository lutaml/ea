# frozen_string_literal: true

module Ea
  module Model
    # Abstract base for Class, DataType, Enumeration, Interface,
    # PrimitiveType — anything that can be a type of a Property, an
    # end of an Association, etc.
    #
    # Concrete subclasses live in their own files and add their own
    # specific attributes (e.g. Enumeration#literals). Source
    # adapters dispatch on the source's type discriminator
    # (t_object.Object_Type, xmi:type) to pick the right subclass.
    class Classifier < Base
      attribute :qualified_name, :string
      attribute :package_id, :string # containing package
      attribute :is_abstract, :boolean, default: false
      attribute :visibility, :string
      attribute :model_kind, :string, default: -> { "classifier" }
      attribute :properties, Property, collection: true, initialize_empty: true
      attribute :operations, Operation, collection: true, initialize_empty: true
      attribute :stereotype_refs, :string, collection: true, initialize_empty: true
      attribute :tagged_values, TaggedValue, collection: true, initialize_empty: true
      attribute :annotations, Annotation, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "qualifiedName", to: :qualified_name
        map "packageId", to: :package_id
        map "isAbstract", to: :is_abstract, render_default: true
        map "visibility", to: :visibility
        map "modelKind", to: :model_kind, render_default: true
        map "properties", to: :properties, render_empty: true
        map "operations", to: :operations, render_empty: true
        map "stereotypeRefs", to: :stereotype_refs, render_empty: true
        map "taggedValues", to: :tagged_values, render_empty: true
        map "annotations", to: :annotations, render_empty: true
      end
    end
  end
end
