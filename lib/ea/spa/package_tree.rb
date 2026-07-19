# frozen_string_literal: true

module Ea
  module Spa
    class PackageTree < Lutaml::Model::Serializable
      attribute :root_ids, :string, collection: true, initialize_empty: true
      attribute :nodes, PackageTreeNode, collection: true, initialize_empty: true

      json do
        map "rootIds", to: :root_ids, render_empty: true
        map "nodes", to: :nodes, render_empty: true
      end
    end
  end
end
