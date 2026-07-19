# frozen_string_literal: true

module Ea
  module Spa
    # A lazy reference: id + URL to where the full shard lives. Used
    # in the skeleton so the frontend can fetch detail on demand
    # rather than upfront.
    class LazyRef < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :url, :string

      json do
        map "id", to: :id
        map "url", to: :url
      end
    end
  end
end
