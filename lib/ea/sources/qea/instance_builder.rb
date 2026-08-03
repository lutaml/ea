# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Translates EA t_object rows of Object_Type="Object" into
      # Ea::Model::InstanceSpecification instances. Slots are parsed
      # from the RunState field, which uses a packed format:
      #
      #   @VAR;Variable=name;Value=val;Op===;@ENDVAR;@VAR;...
      #
      # Each @VAR...@ENDVAR block is one Slot.
      class InstanceBuilder
        RUN_STATE_PATTERN = /
          @VAR;
          (?:Variable=(?<name>[^;]*);)?
          (?:Value=(?<value>[^;]*);)?
          (?:Op=(?<op>[^;]*);)?
          @ENDVAR;
        /x.freeze

        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all
          objects = database.collections[:objects] || []
          objects.filter_map { |row| build_one(row) if instance?(row) }
        end

        def build_one(row)
          Ea::Model::InstanceSpecification.new(
            id: IdNormalizer.from_guid(row.ea_guid),
            name: row.name.to_s,
            classifier_id: classifier_id_for(row),
            classifier_name: classifier_name_for(row),
            package_id: package_id_for(row),
            package_name: package_name_for(row),
            qualified_name: qualified_name_for(row),
            slots: slots_for(row),
            annotations: AnnotationBuilder.from_note(row.note, row.ea_guid,
                                                      kind: "documentation")
          )
        end

        private

        def instance?(row)
          row.object_type == "Object"
        end

        def classifier_id_for(row)
          classifier = database.find_object(row.classifier.to_i) if row.classifier&.to_i&.positive?
          return nil unless classifier

          IdNormalizer.from_guid(classifier.ea_guid)
        end

        def classifier_name_for(row)
          classifier = database.find_object(row.classifier.to_i) if row.classifier&.to_i&.positive?
          return nil unless classifier

          classifier.name.to_s
        end

        def package_id_for(row)
          return nil unless row.package_id&.to_i&.positive?

          pkg = database.find_package(row.package_id.to_i)
          return nil unless pkg

          IdNormalizer.from_guid(pkg.ea_guid)
        end

        def package_name_for(row)
          return nil unless row.package_id&.to_i&.positive?

          pkg = database.find_package(row.package_id.to_i)
          pkg&.name
        end

        # EA's t_object.Name may carry a qualified name with a ":"
        # prefix (e.g. "gml:CodeType"). When the instance is in a
        # nested package the qualified name uses the package path.
        def qualified_name_for(row)
          name = row.name.to_s
          return name if name.empty?

          pkg_name = package_name_for(row)
          pkg_name ? "#{pkg_name}::#{name}" : name
        end

        # Parse the RunState field into Slot instances. Each
        # @VAR;Variable=X;Value=Y;Op=Z;@ENDVAR; is one slot.
        # When Op is absent we default to "=".
        def slots_for(row)
          run_state = row.runstate.to_s
          return [] if run_state.empty?

          run_state.scan(RUN_STATE_PATTERN).map do |(name, value, op)|
            Ea::Model::Slot.new(
              name: name.to_s,
              value: value.to_s,
              op: (op.to_s.empty? ? "=" : op)
            )
          end
        end
      end
    end
  end
end
