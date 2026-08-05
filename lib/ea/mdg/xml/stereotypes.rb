# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class Stereotypes < Lutaml::Model::Serializable
        attribute :items, Stereotype, collection: true

        xml do
          root "Stereotypes"
          map_element "Stereotype", to: :items
        end
      end
    end
  end
end
