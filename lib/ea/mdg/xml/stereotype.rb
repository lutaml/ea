# frozen_string: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class Stereotype < Lutaml::Model::Serializable
        attribute :name, :string
        attribute :notes, :string
        attribute :generalizes, :string
        attribute :base_stereotypes, :string
        attribute :applies_to, AppliesTo
        attribute :tagged_values, TaggedValues

        xml do
          root "Stereotype"
          map_attribute "name", to: :name
          map_attribute "notes", to: :notes
          map_attribute "generalizes", to: :generalizes
          map_attribute "baseStereotypes", to: :base_stereotypes
          map_element "AppliesTo", to: :applies_to
          map_element "TaggedValues", to: :tagged_values
        end
      end
    end
  end
end
