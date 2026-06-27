# frozen_string_literal: true

require "nokogiri"

module Ea
  module Transformers
    module UmlToXmi
      # Low-level XML structural primitives for emitting Sparx-flavored XMI.
      #
      # This class has no UML domain knowledge — it only knows the XML shapes
      # (XMI root, uml:Model, packagedElement, ownedAttribute, …) required to
      # produce a well-formed Sparx XMI document. {Transformer} drives it.
      class Writer
        XMI_NS = "http://www.omg.org/spec/XMI/20131001"
        UML_NS = "http://www.omg.org/spec/UML/20161101"

        attr_reader :builder

        def initialize
          @builder = Nokogiri::XML::Builder.new(encoding: "UTF-8")
        end

        def xmi_root
          @builder["xmi"].XMI(root_attributes) { yield self }
        end

        def documentation(exporter: "ea-rb", exporter_version: Ea::VERSION)
          @builder["xmi"].Documentation(
            exporter: exporter,
            exporterVersion: exporter_version,
          )
        end

        def uml_model(id, name)
          @builder["uml"].Model(
            "xmi:type": "uml:Model",
            "xmi:id": id,
            name: name,
          ) { yield self }
        end

        def packaged_element(uml_type, id, name, **attrs)
          @builder.packagedElement(packaged_attrs(uml_type, id, name, attrs)) do
            yield self if block_given?
          end
        end

        def owned_attribute(id, name, type: nil, visibility: "public")
          attrs = { "xmi:type": "uml:Property", "xmi:id": id, name: name,
                    visibility: visibility }
          attrs[:type] = type if type
          @builder.ownedAttribute(attrs) { yield self if block_given? }
        end

        def owned_operation(id, name, visibility: "public")
          @builder.ownedOperation(
            "xmi:type": "uml:Operation", "xmi:id": id, name: name,
            visibility: visibility,
          ) { yield self if block_given? }
        end

        def owned_literal(id, name)
          @builder.ownedLiteral(
            "xmi:type": "uml:EnumerationLiteral", "xmi:id": id, name: name,
          )
        end

        def generalization(id, general_id)
          @builder.generalization(
            "xmi:type": "uml:Generalization",
            "xmi:id": id,
            general: general_id,
          )
        end

        def to_xml
          @builder.doc.to_xml
        end

        private

        def root_attributes
          { "xmlns:xmi": XMI_NS, "xmlns:uml": UML_NS }
        end

        def packaged_attrs(uml_type, id, name, attrs)
          result = { "xmi:type": uml_type, "xmi:id": id }
          result[:name] = name if name
          result[:"isAbstract"] = "true" if attrs[:is_abstract]
          result[:visibility] = attrs[:visibility] if attrs[:visibility]
          result
        end
      end
    end
  end
end
