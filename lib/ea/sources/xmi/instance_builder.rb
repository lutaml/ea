# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      # Builds Ea::Model::InstanceSpecification objects from
      # uml:InstanceSpecification packaged elements. Slots come from
      # the `runstate` attribute of the element's Extension entry,
      # which carries slot names and operators that the typed
      # `<slot>` children omit.
      class InstanceBuilder
        XMI_TYPE = "uml:InstanceSpecification"
        RUNSTATE_XPATH =
          %(//*[local-name()="element"]/*[local-name()="extendedProperties"][@runstate])

        attr_reader :root, :xmi_path, :classifiers

        def initialize(root, xmi_path, classifiers)
          @root = root
          @xmi_path = xmi_path
          @classifiers = classifiers
        end

        def build_all
          instances = []
          walk(root.model) do |element, package|
            instances << build_one(element, package) if element.type == XMI_TYPE
          end
          instances
        end

        private

        def walk(element, package = nil, &block)
          yield element, package
          element.packaged_element.each do |inner|
            walk(inner, inner.type == "uml:Package" ? inner : package, &block)
          end
        end

        def build_one(element, package)
          id = IdNormalizer.from_xmi_id(element.id)
          properties = extension_properties[id]
          Ea::Model::InstanceSpecification.new(
            id: id,
            name: element.name.to_s,
            role_name: properties&.alias,
            classifier_id: IdNormalizer.from_xmi_id(element.classifier),
            classifier_name: classifier_names[element.classifier],
            stereotype: properties&.stereotype.to_s,
            package_id: package && IdNormalizer.from_xmi_id(package.id),
            package_name: package&.name,
            qualified_name: qualified_name(element, package),
            slots: slots_for(id),
            annotations: AnnotationBuilder.from_element(element, id)
          )
        end

        def qualified_name(element, package)
          name = element.name.to_s
          return name if name.empty? || package.nil?

          "#{package.name}::#{name}"
        end

        def classifier_names
          @classifier_names ||= classifiers.to_h { |c| [c.id, c.name.to_s] }
        end

        def extension_properties
          @extension_properties ||=
            (root.extension&.elements&.element || []).to_h { |e| [e.idref, e.properties] }
        end

        def slots_for(id)
          runstates[id].to_s.scan(Ea::Sources::Qea::InstanceBuilder::RUN_STATE_PATTERN).map do |(name, value, op)|
            Ea::Model::Slot.new(name: name.to_s, value: value.to_s, op: op.to_s.empty? ? "=" : op)
          end
        end

        def runstates
          @runstates ||= extension_runstates
        end

        def extension_runstates
          return {} if xmi_path.nil?

          Nokogiri::XML(File.read(xmi_path))
                  .xpath(RUNSTATE_XPATH)
                  .to_h { |node| [node.parent["xmi:idref"], node["runstate"]] }
        end
      end
    end
  end
end
