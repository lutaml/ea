# frozen_string_literal: true

require "xmi"

module Ea
  module Transformers
    module QeaToXmi
      # Builds MDG technology stereotype definitions as xmi gem model
      # objects for inclusion in the UML model tree.
      #
      # When EA exports a model that references MDG stereotypes, it
      # includes the stereotype DEFINITIONS in the output — each as
      # `<packagedElement xmi:type="uml:Stereotype">` with its tagged
      # values as `<ownedAttribute>` elements, plus an
      # `<uml:Extension>` linking the stereotype to its base metaclass.
      #
      # MDG technologies are registered at runtime via
      # {Ea::Mdg::Registry} (OCP — swap in/out without code changes).
      # The ProfileSerializer queries the registry at call time, so
      # the output reflects whatever MDGs are currently registered.
      #
      # Uses the xmi gem's typed models (PackagedElement, OwnedAttribute,
      # Type) for serialization — no raw XML string building.
      class ProfileSerializer
        UML_TYPE_HREF = "http://www.omg.org/spec/UML/20110701/UML.xmi"

        # @param mdg_registry [Ea::Mdg::Registry, nil]
        def initialize(mdg_registry)
          @mdg_registry = mdg_registry
        end

        # @return [Array<Xmi::Uml::PackagedElement>] stereotype and
        #   extension elements for all registered MDG documents.
        #   Empty array when no registry or no stereotypes.
        #
        # Stereotype ids are the bare names, so two MDGs defining the
        # same name would emit clashing definitions. The first
        # document to define a name wins.
        def call
          return [] unless @mdg_registry

          @mdg_registry.documents
                       .flat_map(&:stereotypes)
                       .uniq(&:name)
                       .flat_map { |stereo| [build_stereotype(stereo), *build_extensions(stereo)] }
        end

        private

        # @return [Xmi::Uml::PackagedElement] the uml:Stereotype element
        def build_stereotype(stereotype)
          ::Xmi::Uml::PackagedElement.new(
            type: "uml:Stereotype",
            id: stereotype.name,
            name: stereotype.name,
            owned_attribute: owned_attributes_for(stereotype)
          )
        end

        # @return [Array<Xmi::Uml::PackagedElement>] one uml:Extension
        #   per applies_to metaclass
        def build_extensions(stereotype)
          stereotype.applies_to.filter_map do |metaclass|
            next nil if metaclass.nil? || metaclass.empty?

            build_extension(stereotype, metaclass)
          end
        end

        # EA carries both ends as one space-separated memberEnd
        # attribute on the Extension and repeats it on the
        # ExtensionEnd — never as child <memberEnd> elements.
        def build_extension(stereotype, metaclass)
          base_id = "#{stereotype.name}-base_#{metaclass}"
          member_ends = "extension_#{stereotype.name} #{base_id}"

          ::Xmi::Uml::PackagedElement.new(
            type: "uml:Extension",
            id: "#{metaclass}_#{stereotype.name}",
            name: "A_#{metaclass}_#{stereotype.name}",
            member_end: member_ends,
            owned_end: [build_extension_end(stereotype, member_ends)]
          )
        end

        def build_extension_end(stereotype, member_ends)
          ::Xmi::Uml::OwnedEnd.new(
            type: "uml:ExtensionEnd",
            id: "extension_#{stereotype.name}",
            name: "extension_#{stereotype.name}",
            member_end: member_ends,
            is_composite: true,
            uml_type: ::Xmi::Uml::Type.new(idref: stereotype.name)
          )
        end

        # All ownedAttribute elements: base_{metaclass} link(s) + one
        # per tagged value.
        def owned_attributes_for(stereotype)
          attrs = base_properties(stereotype)
          attrs.concat(tagged_value_properties(stereotype))
          attrs
        end

        # @return [Array<Xmi::Uml::OwnedAttribute>] one base_{mc}
        #   property per applies_to metaclass, linking the stereotype
        #   to its UML base via the Extension association.
        def base_properties(stereotype)
          stereotype.applies_to.filter_map do |metaclass|
            next nil if metaclass.nil? || metaclass.empty?

            build_base_property(stereotype, metaclass)
          end
        end

        def build_base_property(stereotype, metaclass)
          ::Xmi::Uml::OwnedAttribute.new(
            type: "uml:Property",
            id: "#{stereotype.name}-base_#{metaclass}",
            name: "base_#{metaclass}",
            association: "#{metaclass}_#{stereotype.name}",
            uml_type: ::Xmi::Uml::Type.new(href: "#{UML_TYPE_HREF}##{metaclass}")
          )
        end

        # @return [Array<Xmi::Uml::OwnedAttribute>] one per tagged value
        def tagged_value_properties(stereotype)
          stereotype.tagged_values.map do |tv|
            build_tagged_value_property(stereotype.name, tv)
          end
        end

        def build_tagged_value_property(stereo_name, tagged_value)
          ::Xmi::Uml::OwnedAttribute.new(
            type: "uml:Property",
            id: "#{stereo_name}-#{tagged_value.name}",
            name: tagged_value.name,
            uml_type: ::Xmi::Uml::Type.new(href: "#{UML_TYPE_HREF}##{normalize_type(tagged_value.type)}")
          )
        end

        # Map MDG tagged value types to UML XMI primitive type names.
        # Unknown types default to String (matches EA's behaviour).
        def normalize_type(raw)
          return "String" if raw.nil? || raw.empty?

          TYPE_MAP.fetch(raw.to_s.downcase, "String")
        end

        TYPE_MAP = {
          "boolean" => "Boolean",
          "integer" => "Integer",
          "int" => "Integer",
          "real" => "Real",
          "double" => "Real",
          "string" => "String",
          "enumeration" => "String",
          "class" => "Class"
        }.freeze
      end
    end
  end
end
