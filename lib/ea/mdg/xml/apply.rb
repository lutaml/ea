# frozen_string: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class Apply < Lutaml::Model::Serializable
        attribute :type, :string

        xml do
          root "Apply"
          map_attribute "type", to: :type
        end
      end
    end
  end
end
