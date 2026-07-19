# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Builds Ea::Model::TaggedValue instances from EA's
      # t_objectproperties (and t_attributetags for attribute-level
      # tagged values). Each row is one key/value pair; we keep the
      # optional stereotype scope if EA recorded one.
      class TaggedValueBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def for_object(ea_guid)
          rows = database.tagged_values_for_element(ea_guid) || []
          rows.map { |row| build_from_row(row, ea_guid) }
        end

        def for_attribute(attribute_row)
          return [] unless attribute_row.respond_to?(:ea_guid)

          rows = database.tagged_values_for_element(attribute_row.ea_guid) || []
          rows.map { |row| build_from_row(row, attribute_row.ea_guid) }
        end

        def build_from_row(row, owner_guid)
          Ea::Model::TaggedValue.new(
            id: IdNormalizer.synthetic("tv", owner_guid, row.property&.gsub(/\W+/, "_")),
            key: row.property,
            value: row.value
          )
        end
      end
    end
  end
end
