# frozen_string_literal: true

module Ea
  module Spa
    # One row in the SPA skeleton: the minimal info needed to
    # render the sidebar, do name searches, and route to a shard.
    # Everything else (properties, operations, etc.) lives in the
    # per-entity Shard.
    class SkeletonEntry < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :name, :string
      attribute :kind, :string            # class|enumeration|data_type|...
      attribute :package_id, :string
      attribute :qualified_name, :string
      attribute :shard_url, :string       # where to fetch the full Shard

      json do
        map "id", to: :id
        map "name", to: :name
        map "kind", to: :kind
        map "packageId", to: :package_id
        map "qualifiedName", to: :qualified_name
        map "shardUrl", to: :shard_url
      end
    end
  end
end
