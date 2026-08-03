# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Builds Ea::Model::TaggedValue instances from EA's
      # t_taggedvalue AND t_objectproperties tables. EA stores UML
      # profile tagged values in t_taggedvalue (keyed by ElementID
      # GUID), and per-object custom properties in t_objectproperties
      # (keyed by Object_ID integer). Both surface as tagged values
      # in the SVG output and merge into one list per classifier.
      class TaggedValueBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        # Build tagged values for an EA object. Pass both the
        # GUID (for t_taggedvalue lookups) and the integer EA
        # Object_ID (for t_objectproperties lookups).
        def for_object(ea_guid, ea_object_id: nil)
          rows = database.tagged_values_for_element(ea_guid) || []
          tv = rows.map { |row| build_from_tagged_value(row, ea_guid) }
          return tv unless ea_object_id

          prop_rows = database.properties_for_object(ea_object_id) || []
          tv + prop_rows.map { |row| build_from_object_property(row) }
        end

        def for_attribute(attribute_row)
          return [] unless attribute_row.is_a?(Ea::Qea::Models::EaAttribute)

          rows = database.tagged_values_for_element(attribute_row.ea_guid) || []
          rows.map { |row| build_from_tagged_value(row, attribute_row.ea_guid) }
        end

        def build_from_tagged_value(row, owner_guid)
          Ea::Model::TaggedValue.new(
            id: IdNormalizer.synthetic("tv", owner_guid,
                                       row.tag&.gsub(/\W+/, "_")),
            key: row.tag,
            value: row.value
          )
        end

        def build_from_object_property(row)
          Ea::Model::TaggedValue.new(
            id: IdNormalizer.synthetic("op", row.ea_object_id.to_s,
                                       row.property&.gsub(/\W+/, "_")),
            key: row.property,
            value: row.value
          )
        end
      end
    end
  end
end
