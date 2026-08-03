# frozen_string: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class TaggedValues < Lutaml::Model::Serializable
        attribute :tags, Tag, collection: true

        xml do
          root "TaggedValues"
          map_element "Tag", to: :tags
        end
      end
    end
  end
end
