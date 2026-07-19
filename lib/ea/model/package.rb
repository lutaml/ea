# frozen_string_literal: true

module Ea
  module Model
    # A Package: hierarchical container for sub-packages and
    # classifiers. References children by id (flat index in the
    # Document) rather than nesting, so the same model is cheap to
    # serialize, shard, and walk from any entry point.
    class Package < Base
      attribute :parent_id, :string # nil for root
      attribute :qualified_name, :string
      attribute :sub_package_ids, :string, collection: true,
                                           initialize_empty: true
      attribute :classifier_ids, :string, collection: true,
                                          initialize_empty: true
      attribute :diagram_ids, :string, collection: true,
                                       initialize_empty: true
      attribute :stereotype_refs, :string, collection: true, initialize_empty: true
      attribute :tagged_values, TaggedValue, collection: true, initialize_empty: true
      attribute :annotations, Annotation, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "parentId", to: :parent_id
        map "qualifiedName", to: :qualified_name
        map "subPackageIds", to: :sub_package_ids, render_empty: true
        map "classifierIds", to: :classifier_ids, render_empty: true
        map "diagramIds", to: :diagram_ids, render_empty: true
        map "stereotypeRefs", to: :stereotype_refs, render_empty: true
        map "taggedValues", to: :tagged_values, render_empty: true
        map "annotations", to: :annotations, render_empty: true
      end
    end
  end
end
