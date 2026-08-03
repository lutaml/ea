# frozen_string: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class Tag < Lutaml::Model::Serializable
        attribute :name, :string
        attribute :type, :string
        attribute :description, :string
        attribute :unit, :string
        attribute :values, :string
        attribute :default, :string

        xml do
          root "Tag"
          map_attribute "name", to: :name
          map_attribute "type", to: :type
          map_attribute "description", to: :description
          map_attribute "unit", to: :unit
          map_attribute "values", to: :values
          map_attribute "default", to: :default
        end
      end
    end
  end
end
