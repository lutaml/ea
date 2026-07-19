# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Translates EA t_operation + t_operationparams rows into
      # Ea::Model::Operation instances with owned Parameters.
      class OperationBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all_for(owner_object)
          ops = database.operations_for_object(owner_object.ea_object_id) || []
          ops.map { |row| build_one(row, owner_object) }
        end

        def build_one(row, owner_object)
          Ea::Model::Operation.new(
            id: IdNormalizer.from_guid(row.ea_guid),
            name: row.name,
            owner_id: IdNormalizer.from_guid(owner_object.ea_guid),
            qualified_name: "#{owner_object.name}::#{row.name}",
            return_type_name: row.type,
            visibility: visibility_from_scope(row.scope),
            is_static: boolean(row.isstatic),
            is_abstract: boolean(row.abstract),
            parameters: build_parameters(row),
            annotations: AnnotationBuilder.from_note(row.notes, row.ea_guid,
                                                     kind: "documentation")
          )
        end

        private

        def build_parameters(operation_row)
          params = database.operation_params_for(operation_row.operationid) || []
          params.map.with_index do |p, idx|
            Ea::Model::Parameter.new(
              id: IdNormalizer.from_guid(p.ea_guid),
              name: p.name,
              ordinal: p.pos || idx,
              direction: direction_from_kind(p.kind),
              type_name: p.type,
              default_value: p.default
            )
          end
        end

        def direction_from_kind(kind)
          case kind.to_s
          when "1", "out" then "out"
          when "2", "inout" then "inout"
          when "3", "return" then "return"
          else "in"
          end
        end

        def visibility_from_scope(scope)
          case scope.to_s
          when "Public" then "public"
          when "Protected" then "protected"
          when "Private" then "private"
          else "public"
          end
        end

        def boolean(value)
          case value.to_s
          when "1", "true", "TRUE" then true
          else false
          end
        end
      end
    end
  end
end
