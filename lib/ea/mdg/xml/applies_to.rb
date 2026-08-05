# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Mdg
    module Xml
      class AppliesTo < Lutaml::Model::Serializable
        attribute :applies, Apply, collection: true

        xml do
          root "AppliesTo"
          map_element "Apply", to: :applies
        end
      end
    end
  end
end
