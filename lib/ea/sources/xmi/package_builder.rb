# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Translates XMI uml:Package elements into Ea::Model::Package
      # instances. Walks the packaged_element tree recursively so
      # nested packages are picked up.
      class PackageBuilder
        attr_reader :root

        def initialize(root)
          @root = root
        end

        def build_all
          packages = []
          walk_packages(root.model, nil) do |pe, parent_id|
            packages << build_one(pe, parent_id: parent_id)
          end
          packages
        end

        def walk_packages(element, parent_id, &block)
          element.packaged_element.each do |inner|
            next unless inner.type == "uml:Package"

            id = IdNormalizer.from_xmi_id(inner.id)
            yield inner, parent_id
            walk_packages(inner, id, &block)
          end
        end

        def build_one(packaged_element, parent_id:)
          id = IdNormalizer.from_xmi_id(packaged_element.id)
          Ea::Model::Package.new(
            id: id,
            name: packaged_element.name,
            parent_id: parent_id,
            qualified_name: packaged_element.name,
            sub_package_ids: child_package_ids(packaged_element),
            classifier_ids: child_classifier_ids(packaged_element),
            annotations: AnnotationBuilder.from_element(packaged_element, id)
          )
        end

        private

        def packages_for(model_element)
          return [] unless model_element

          model_element.packaged_element.select { |pe| pe.type == "uml:Package" }
        end

        def child_package_ids(packaged_element)
          packaged_element.packaged_element
                          .select { |pe| pe.type == "uml:Package" }
                          .map { |pe| IdNormalizer.from_xmi_id(pe.id) }
                          .compact
        end

        def child_classifier_ids(packaged_element)
          packaged_element.packaged_element
                          .filter_map do |pe|
                            next unless TypeClassifierMap.classifier_type?(pe.type)

                            IdNormalizer.from_xmi_id(pe.id)
                          end
        end
      end
    end
  end
end
