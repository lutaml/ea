# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class UmlProfile < Lutaml::Model::Serializable
        attribute :profiletype, :string
        attribute :documentation, Documentation
        attribute :content, Content

        xml do
          root "UMLProfile"
          map_attribute "profiletype", to: :profiletype
          map_element "Documentation", to: :documentation
          map_element "Content", to: :content
        end
      end
    end
  end
end
