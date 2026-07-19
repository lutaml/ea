# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Translates EA t_attribute rows into Ea::Model::Property
      # instances. Multiplicity is parsed from EA's `LowerBound` /
      # `UpperBound` columns (with `*` represented as -1 in the
      # model).
      class PropertyBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all_for(owner_object)
          attrs = database.attributes_for_object(owner_object.ea_object_id) || []
          attrs.map { |row| build_one(row, owner_object) }
        end

        def build_one(row, owner_object)
          Ea::Model::Property.new(
            id: IdNormalizer.from_guid(row.ea_guid),
            name: row.name,
            owner_id: IdNormalizer.from_guid(owner_object.ea_guid),
            type_name: row.type,
            qualified_name: "#{owner_object.name}::#{row.name}",
            multiplicity_lower: parse_lower(row),
            multiplicity_upper: parse_upper(row),
            default_value: row.default,
            is_ordered: boolean(row.isordered),
            is_unique: !boolean(row.allowduplicates),
            visibility: visibility_from_scope(row.scope),
            aggregation: "none",
            stereotype_refs: stereotype_refs(row),
            tagged_values: TaggedValueBuilder.new(database).for_attribute(row),
            annotations: AnnotationBuilder.from_note(row.notes, row.ea_guid,
                                                     kind: "documentation")
          )
        end

        private

        def parse_lower(row)
          Integer(row.lowerbound || 1)
        rescue StandardError
          1
        end

        def parse_upper(row)
          return -1 if row.upperbound.to_s == "*"

          begin
            Integer(row.upperbound || 1)
          rescue StandardError
            1
          end
        end

        def boolean(value)
          case value.to_s
          when "1", "true", "TRUE" then true
          else false
          end
        end

        def visibility_from_scope(scope)
          case scope.to_s
          when "Public" then "public"
          when "Protected" then "protected"
          when "Private" then "private"
          when "Package" then "package"
          else "public"
          end
        end

        def stereotype_refs(row)
          refs = []
          refs << row.stereotype if row.stereotype && !row.stereotype.empty?
          refs
        end
      end
    end
  end
end
