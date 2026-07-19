# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Builds Ea::Model::Stereotype instances from EA's
      # t_stereotypes table and from the `stereotype` column on
      # individual elements. EA's stereotype storage is messy — a
      # stereotype can be declared globally and applied per-element
      # by name. We treat each distinct applied stereotype name as
      # an instance and reference it from the applying element.
      class StereotypeBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all
          stereotypes = database.collections[:stereotypes] || []
          stereotypes.map { |st| build_one(st) }
        end

        def build_one(stereotype_row)
          name = stereotype_row.stereotype
          Ea::Model::Stereotype.new(
            id: IdNormalizer.from_guid(stereotype_row.ea_guid) ||
                IdNormalizer.synthetic("stereotype", name),
            name: name,
            qualified_name: name,
            profile: stereotype_row.appliesto
          )
        end

        # Apply references: which stereotypes apply to a given EA object.
        def refs_for_object(object)
          refs = []
          refs << object.stereotype if object.stereotype && !object.stereotype.empty?
          refs.uniq
        end
      end
    end
  end
end
