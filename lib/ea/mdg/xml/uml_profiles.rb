# frozen_string: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class UmlProfiles < Lutaml::Model::Serializable
        attribute :profiles, UmlProfile, collection: true, initialize_empty: true

        xml do
          root "UMLProfiles"
          map_element "UMLProfile", to: :profiles
        end
      end
    end
  end
end
