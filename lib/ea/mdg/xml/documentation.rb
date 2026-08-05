# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class Documentation < Lutaml::Model::Serializable
        attribute :id, :string
        attribute :name, :string
        attribute :version, :string
        attribute :notes, :string

        xml do
          root "Documentation"
          map_attribute "id", to: :id
          map_attribute "name", to: :name
          map_attribute "version", to: :version
          map_attribute "notes", to: :notes
        end
      end
    end
  end
end
