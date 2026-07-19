# frozen_string_literal: true

module Ea
  module Model
    # Common base for every Ea::Model type.
    #
    # Every model element has a stable identity (`id`) used to
    # reference it from other elements (e.g. a Property refers to its
    # type by id, a Relationship refers to its ends by id). Source
    # adapters normalize the source-specific identifier (xmi:id,
    # ea_guid, etc.) into this `id` field.
    class Base < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :name, :string

      json do
        map "id", to: :id
        map "name", to: :name
      end

      yaml do
        map "id", to: :id
        map "name", to: :name
      end
    end
  end
end
