# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Translates XMI classifier elements (uml:Class, uml:DataType,
      # uml:Enumeration, uml:Interface, uml:PrimitiveType) into the
      # appropriate Ea::Model::Classifier subclass. Uses
      # TypeClassifierMap for dispatch (OCP).
      class ClassifierBuilder
        attr_reader :root

        def initialize(root)
          @root = root
        end

        def build_all
          classifiers = []
          walk(root.model) do |element, parent_pkg|
            next unless TypeClassifierMap.classifier_type?(element.type)

            classifiers << build_one(element, parent_pkg)
          end
          classifiers
        end

        def build_one(element, containing_package)
          klass = TypeClassifierMap.class_for(element.type)
          args = common_args(element, containing_package)
          args.merge!(enumeration_args(element)) if klass == Ea::Model::Enumeration
          klass.new(**args)
        end

        private

        # Depth-first walk of the packaged_element tree. Yields each
        # element with its containing uml:Package (or nil at the
        # model root).
        def walk(element, parent_pkg = nil, &block)
          yield element, parent_pkg if block
          element.packaged_element.each do |inner|
            new_parent = inner.type == "uml:Package" ? inner : parent_pkg
            walk(inner, new_parent, &block)
          end
        end

        def common_args(element, containing_package)
          id = IdNormalizer.from_xmi_id(element.id)
          {
            id: id,
            name: element.name,
            package_id: containing_package && IdNormalizer.from_xmi_id(containing_package.id),
            qualified_name: qualified_name(element, containing_package),
            is_abstract: boolean(element.is_abstract),
            visibility: element.visibility,
            properties: PropertyBuilder.new.build_all_for(element),
            operations: OperationBuilder.new.build_all_for(element),
            annotations: AnnotationBuilder.from_element(element, id)
          }
        end

        def enumeration_args(element)
          literals = element.owned_literal.map.with_index do |lit, idx|
            Ea::Model::EnumerationLiteral.new(
              id: IdNormalizer.from_xmi_id(lit.id) ||
                  IdNormalizer.synthetic_id(element.id, "literal", idx.to_s),
              name: lit.name,
              value: lit.name,
              ordinal: idx
            )
          end
          { literals: literals }
        end

        def qualified_name(element, containing_package)
          pkg_name = containing_package&.name
          pkg_name ? "#{pkg_name}::#{element.name}" : element.name
        end

        def boolean(value)
          case value
          when true, "true" then true
          else false
          end
        end
      end
    end
  end
end
