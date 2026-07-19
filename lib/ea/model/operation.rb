# frozen_string_literal: true

module Ea
  module Model
    # An Operation on a Classifier (method). Parameters are owned
    # composition-style.
    class Operation < Base
      attribute :owner_id, :string
      attribute :qualified_name, :string
      attribute :return_type_name, :string
      attribute :is_static, :boolean, default: false
      attribute :is_abstract, :boolean, default: false
      attribute :visibility, :string
      attribute :parameters, Parameter, collection: true, initialize_empty: true
      attribute :stereotype_refs, :string, collection: true, initialize_empty: true
      attribute :annotations, Annotation, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "ownerId", to: :owner_id
        map "qualifiedName", to: :qualified_name
        map "returnTypeName", to: :return_type_name
        map "isStatic", to: :is_static, render_default: true
        map "isAbstract", to: :is_abstract, render_default: true
        map "visibility", to: :visibility
        map "parameters", to: :parameters, render_empty: true
        map "stereotypeRefs", to: :stereotype_refs, render_empty: true
        map "annotations", to: :annotations, render_empty: true
      end
    end
  end
end
