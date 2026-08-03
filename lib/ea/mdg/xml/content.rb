# frozen_string: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class Content < Lutaml::Model::Serializable
        attribute :stereotypes, Stereotypes

        xml do
          root "Content"
          map_element "Stereotypes", to: :stereotypes
        end
      end
    end
  end
end
