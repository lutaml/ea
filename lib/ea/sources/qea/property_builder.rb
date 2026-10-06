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
            # EA stores the literal "<undefined>" in t_attribute.Type
            # for enumeration literals; EA's published SVGs render
            # those rows as bare names with no type suffix.
            type_name: normalize_type(row.type),
            qualified_name: "#{owner_object.name}::#{row.name}",
            multiplicity_lower: parse_lower(row),
            multiplicity_upper_raw: raw_upper(row),
            multiplicity_upper: parse_upper(row),
            default_value: row.default,
            is_derived: boolean(row.derived),
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

        # EA stores some bounds as literal text ("n"); those render
        # verbatim in attribute lines while computed-unbounded bounds
        # render as "*" (verified against EA-published SVGs).
        def raw_upper(row)
          raw = row.upperbound.to_s
          raw.match?(/\A[nN]\z/) ? raw.downcase : nil
        end

        def normalize_type(type)
          text = type.to_s
          return nil if text.empty? || text == "<undefined>"

          text
        end

        def parse_lower(row)
          Integer(row.lowerbound || 1)
        rescue StandardError
          1
        end

        def parse_upper(row)
          raw = row.upperbound.to_s
          return -1 if raw.match?(/\A[*nN]\z/)

          begin
            Integer(raw.empty? ? 1 : raw)
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
