# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class Technology < Lutaml::Model::Serializable
        attribute :version, :string
        attribute :documentation, Documentation
        attribute :uml_profiles, UmlProfiles
        # Some MDG files place additional <UMLProfile> elements
        # as direct children of <MDG.Technology> alongside
        # <UMLProfiles>, not inside it.
        attribute :standalone_profiles, UmlProfile, collection: true,
                                                   initialize_empty: true

        xml do
          root "MDG.Technology"
          map_attribute "version", to: :version
          map_element "Documentation", to: :documentation
          map_element "UMLProfiles", to: :uml_profiles
          map_element "UMLProfile", to: :standalone_profiles
        end
      end
    end
  end
end
