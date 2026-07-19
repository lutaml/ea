# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Translates EA t_object rows (filtered to classifier types)
      # into the appropriate Ea::Model::Classifier subclass. Uses
      # ObjectClassifierMap for dispatch (OCP — new classifier
      # kinds need no edit here).
      class ClassifierBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all
          classifiers = []
          each_classifier_object do |object|
            classifiers << build_one(object)
          end
          classifiers
        end

        def build_one(object)
          klass = ObjectClassifierMap.class_for(object.object_type)
          args = common_args(object)
          args.merge!(enumeration_args(object)) if klass == Ea::Model::Enumeration
          klass.new(**args)
        end

        private

        def each_classifier_object
          objects = database.collections[:objects] || []
          objects.each do |obj|
            next unless classifier_type?(obj.object_type)

            yield obj
          end
        end

        def classifier_type?(object_type)
          ObjectClassifierMap::LOOKUP.key?(object_type)
        end

        def common_args(object)
          {
            id: IdNormalizer.from_guid(object.ea_guid),
            name: object.name,
            package_id: package_id_for(object),
            qualified_name: qualified_name_for(object),
            is_abstract: abstract?(object),
            visibility: visibility_from_scope(object.scope),
            properties: PropertyBuilder.new(database).build_all_for(object),
            operations: OperationBuilder.new(database).build_all_for(object),
            stereotype_refs: stereotype_refs_for(object),
            tagged_values: TaggedValueBuilder.new(database).for_object(object.ea_guid),
            annotations: AnnotationBuilder.from_note(object.note, object.ea_guid,
                                                     kind: "documentation")
          }
        end

        def enumeration_args(object)
          literals = enumeration_literals_for(object)
          { literals: literals }
        end

        def enumeration_literals_for(object)
          # EA stores enum literals as attributes with no type, or as
          # child t_object rows tagged as Literal. We pick them up
          # from attributes where type is empty/nil and treat the
          # attribute name as the literal value.
          attrs = database.attributes_for_object(object.ea_object_id) || []
          attrs.map.with_index do |attr, idx|
            Ea::Model::EnumerationLiteral.new(
              id: IdNormalizer.from_guid(attr.ea_guid),
              name: attr.name,
              value: attr.default || attr.name,
              ordinal: idx
            )
          end
        end

        def package_id_for(object)
          pkg = database.find_package(object.package_id)
          return nil unless pkg

          IdNormalizer.from_guid(pkg.ea_guid)
        end

        def qualified_name_for(object)
          pkg = database.find_package(object.package_id)
          pkg_prefix = pkg&.xmlpath || pkg&.name
          pkg_prefix ? "#{pkg_prefix}::#{object.name}" : object.name
        end

        def abstract?(object)
          %w[1 true].include?(object.abstract.to_s)
        end

        def visibility_from_scope(scope)
          case scope.to_s
          when "Public" then "public"
          when "Protected" then "protected"
          when "Private" then "private"
          else "public"
          end
        end

        def stereotype_refs_for(object)
          refs = []
          refs << object.stereotype if object.stereotype && !object.stereotype.empty?
          refs
        end
      end
    end
  end
end
