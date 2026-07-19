# frozen_string_literal: true

module Ea
  module Spa
    # One searchable row. MiniSearch-compatible shape: id, name,
    # qualifiedName, type, package, content — all searchable, with
    # `boost` weighting source-type importance.
    class SearchEntry < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :kind, :string              # class|enumeration|package|...
      attribute :name, :string
      attribute :qualified_name, :string
      attribute :package, :string
      attribute :content, :string           # flattened searchable text
      attribute :boost, :float, default: -> { 1.0 }

      json do
        map "id", to: :id
        map "kind", to: :kind
        map "name", to: :name
        map "qualifiedName", to: :qualified_name
        map "package", to: :package
        map "content", to: :content
        map "boost", to: :boost, render_default: true
      end
    end
  end
end
