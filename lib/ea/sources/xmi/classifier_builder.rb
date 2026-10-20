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
          root.model.packaged_element.each do |top|
            walk(top, top.type == "uml:Package" ? top : nil) do |element, parent_pkg, owner_class|
              next unless TypeClassifierMap.classifier_type?(element.type)

              classifiers << build_one(element, parent_pkg, owner_class)
            end
          end
          classifiers
        end

        def build_one(element, containing_package, owner_class = nil)
          klass = TypeClassifierMap.class_for(element.type)
          args = common_args(element, containing_package, owner_class)
          args.merge!(enumeration_args(element)) if klass == Ea::Model::Enumeration
          klass.new(**args)
        end

        private

        # Depth-first walk of the packaged_element and nestedClassifier
        # trees. Yields each element with its containing uml:Package
        # (nil at the model root) and the uml:Class that nests it
        # (nil unless it is a nestedClassifier of a class).
        def walk(element, parent_pkg = nil, owner_class = nil, &block)
          yield element, parent_pkg, owner_class if block
          element.packaged_element.each do |inner|
            new_parent = inner.type == "uml:Package" ? inner : parent_pkg
            walk(inner, new_parent, nil, &block)
          end
          element.nested_classifier.each do |inner|
            walk(inner, parent_pkg, element, &block)
          end
        end

        def common_args(element, containing_package, owner_class)
          id = IdNormalizer.from_xmi_id(element.id)
          nested_parent = owner_class&.name
          {
            id: id,
            name: element.name,
            package_id: containing_package && IdNormalizer.from_xmi_id(containing_package.id),
            nested_parent_name: nested_parent,
            qualified_name: qualified_name(element, containing_package, nested_parent),
            is_abstract: boolean(element.is_abstract),
            visibility: element.visibility,
            properties: PropertyBuilder.new.build_all_for(element),
            operations: OperationBuilder.new.build_all_for(element),
            annotations: annotations_for(element, id)
          }
        end

        def annotations_for(element, id)
          AnnotationBuilder.from_element(element, id) +
            AnnotationBuilder.from_documentation(documentation_by_id[id], id)
        end

        def documentation_by_id
          @documentation_by_id ||=
            (root.extension&.elements&.element || []).to_h { |e| [e.idref, e.properties&.documentation] }
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

        # A name that already carries a namespace prefix
        # (e.g. "gml:CodeType") is the qualified name as saved; a
        # nested classifier is prefixed with its owner class.
        def qualified_name(element, containing_package, nested_parent)
          name = element.name.to_s
          return name if name.include?(":")
          return "#{nested_parent}::#{name}" if nested_parent

          pkg_name = containing_package&.name
          pkg_name ? "#{pkg_name}::#{name}" : name
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
