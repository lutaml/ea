# frozen_string_literal: true

module Ea
  module Spa
    class SearchIndex < Lutaml::Model::Serializable
      attribute :version, :string, default: -> { "1.0" }
      attribute :fields, :string, collection: true,
                                  default: -> { %w[name qualifiedName kind package content] }
      attribute :entries, SearchEntry, collection: true, initialize_empty: true

      json do
        map "version", to: :version, render_default: true
        map "fields", to: :fields, render_default: true
        map "entries", to: :entries, render_empty: true
      end
    end
  end
end
