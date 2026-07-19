# frozen_string_literal: true

module Ea
  module Spa
    # One node in the SPA's package navigation tree. References
    # sub-packages and classifiers by id — the frontend resolves
    # them via the skeleton index.
    class PackageTreeNode < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :name, :string
      attribute :parent_id, :string
      attribute :child_ids, :string, collection: true, initialize_empty: true
      attribute :classifier_ids, :string, collection: true, initialize_empty: true
      attribute :diagram_ids, :string, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "parentId", to: :parent_id
        map "childIds", to: :child_ids, render_empty: true
        map "classifierIds", to: :classifier_ids, render_empty: true
        map "diagramIds", to: :diagram_ids, render_empty: true
      end
    end
  end
end
