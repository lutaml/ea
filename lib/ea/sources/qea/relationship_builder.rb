# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Translates EA t_connector rows into the appropriate
      # Ea::Model::Relationship subclass. Dispatches on
      # `Connector_Type` via ConnectorRelationshipMap.
      class RelationshipBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all
          connectors = database.collections[:connectors] || []
          connectors.filter_map { |row| build_one(row) }
        end

        def build_one(row)
          klass = ConnectorRelationshipMap.class_for(row.connector_type)
          args = common_args(row)
          args.merge!(association_args(row)) if klass == Ea::Model::Association
          klass.new(**args)
        end

        private

        def common_args(row)
          {
            id: IdNormalizer.from_guid(row.ea_guid),
            name: row.name,
            qualified_name: row.name,
            annotations: AnnotationBuilder.from_note(row.notes, row.ea_guid,
                                                     kind: "documentation")
          }
        end

        def association_args(row)
          {
            source_id: id_for_object_id(row.start_object_id),
            target_id: id_for_object_id(row.end_object_id),
            source_role_name: row.sourcerole,
            target_role_name: row.destrole,
            source_multiplicity_lower: parse_lower(row.sourcecard),
            source_multiplicity_upper: parse_upper(row.sourcecard),
            target_multiplicity_lower: parse_lower(row.destcard),
            target_multiplicity_upper: parse_upper(row.destcard),
            source_aggregation: ConnectorRelationshipMap
                                .source_aggregation_for(row.connector_type),
            target_aggregation: aggregation_from(row.destaccess),
            source_navigable: navigable?(row.sourceaccess, row.direction,
                                         :source),
            target_navigable: navigable?(row.destaccess, row.direction, :target)
          }
        end

        def id_for_object_id(ea_object_id)
          obj = database.find_object(ea_object_id)
          return nil unless obj

          IdNormalizer.from_guid(obj.ea_guid)
        end

        def parse_lower(cardinality)
          return 1 if cardinality.nil? || cardinality.empty?

          # EA format: "1", "0..*", "1..1", etc. Take the first number.
          begin
            Integer(cardinality.split("..").first)
          rescue StandardError
            1
          end
        end

        def parse_upper(cardinality)
          return 1 if cardinality.nil? || cardinality.empty?

          upper = cardinality.split("..").last
          return -1 if upper == "*"

          begin
            Integer(upper)
          rescue StandardError
            1
          end
        end

        def aggregation_from(access_value)
          case access_value.to_s
          when "0" then "none"
          when "1" then "shared"
          when "2" then "composite"
          else "none"
          end
        end

        def navigable?(_access, direction, end_label)
          # EA's navigability is messy. Treat unspecified direction
          # as bidirectional, "Source -> Destination" as target-only
          # navigable, etc. Conservative default: both ends navigable.
          case direction.to_s
          when "<->", "" then true
          when "->" then end_label == :target
          when "<-" then end_label == :source
          else true
          end
        end
      end
    end
  end
end
