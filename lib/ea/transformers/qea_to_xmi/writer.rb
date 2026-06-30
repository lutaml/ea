# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Low-level XML primitives for Sparx XMI emission.
      #
      # Knows the XML shapes (root, model, packagedElement, ownedAttribute,
      # generalization, memberEnd, ownedEnd, multiplicity, comment, etc.) but
      # has no domain knowledge — the orchestrator and emitters decide what to
      # emit; this class only knows how to emit it correctly.
      #
      # Delegating to {XmlBuilder} (rather than Nokogiri::XML::Builder) keeps
      # the Sparx mixed-prefix style: `<uml:Model>` with unprefixed children.
      class Writer
        attr_reader :builder

        def initialize
          @builder = XmlBuilder.new
        end

        def xmi_root(namespaces:)
          @builder.root(namespaces) { yield self }
        end

        def documentation(exporter:, exporter_version:, exporter_id: nil)
          attrs = { exporter: exporter, exporterVersion: exporter_version }
          attrs[:exporterID] = exporter_id if exporter_id
          @builder.Documentation(attrs)
        end

        def uml_model(name:)
          @builder.Model("xmi:type": "uml:Model", name: name) do
            yield self
          end
        end

        def packaged_element(xmi_type:, xmi_id:, **attrs)
          @builder.packagedElement(
            packaged_attrs(xmi_type, xmi_id, attrs),
          ) { yield self if block_given? }
        end

        def owned_attribute(xmi_id:, name: nil, type: nil, visibility: "private",
                            association: nil, **attrs)
          emit_property_container(
            tag: :ownedAttribute,
            xmi_id: xmi_id,
            name: name,
            type: type,
            visibility: visibility,
            association: association,
            **attrs,
          ) { yield self if block_given? }
        end

        def owned_end(xmi_id:, name: nil, type: nil, visibility: "private",
                      association: nil, aggregation: nil, **attrs)
          emit_property_container(
            tag: :ownedEnd,
            xmi_id: xmi_id,
            name: name,
            type: type,
            visibility: visibility,
            association: association,
            aggregation: aggregation,
            **attrs,
          ) { yield self if block_given? }
        end

        def member_end(xmi_id_ref:)
          @builder.memberEnd("xmi:idref": xmi_id_ref)
        end

        def type_reference(xmi_id_ref:)
          @builder.type("xmi:idref": xmi_id_ref)
        end

        def lower_value(xmi_id:, value:)
          @builder.lowerValue(
            "xmi:type": "uml:LiteralInteger",
            "xmi:id": xmi_id,
            value: value,
          )
        end

        def upper_value(xmi_id:, value:)
          @builder.upperValue(
            "xmi:type": "uml:LiteralUnlimitedNatural",
            "xmi:id": xmi_id,
            value: value,
          )
        end

        def default_value(xmi_id:, value:, xmi_type: "uml:LiteralString")
          @builder.defaultValue(
            "xmi:type": xmi_type,
            "xmi:id": xmi_id,
            value: value,
          )
        end

        def owned_operation(xmi_id:, name:, visibility: "private",
                            is_static: nil, is_abstract: nil)
          attrs = {
            "xmi:type": "uml:Operation",
            "xmi:id": xmi_id,
            name: name,
            visibility: visibility,
          }
          attrs[:isStatic] = "true" if is_static
          attrs[:isAbstract] = "true" if is_abstract
          @builder.ownedOperation(attrs) { yield self if block_given? }
        end

        def owned_parameter(xmi_id:, name:, type: nil, kind: "in")
          attrs = { "xmi:type": "uml:Parameter", "xmi:id": xmi_id, name: name }
          attrs[:type] = type if type
          attrs[:direction] = kind if kind && kind != "in"
          @builder.ownedParameter(attrs)
        end

        def owned_literal(xmi_id:, name:)
          @builder.ownedLiteral(
            "xmi:type": "uml:EnumerationLiteral",
            "xmi:id": xmi_id,
            name: name,
          )
        end

        def generalization(xmi_id:, general_id:)
          @builder.generalization(
            "xmi:type": "uml:Generalization",
            "xmi:id": xmi_id,
            general: general_id,
          )
        end

        def implementation(xmi_id:, supplier_id:)
          @builder.interfaceRealization(
            "xmi:type": "uml:InterfaceRealization",
            "xmi:id": xmi_id,
            contract: supplier_id,
          )
        end

        def dependency(xmi_id:, supplier_id:)
          @builder.packagedElement(
            "xmi:type": "uml:Dependency",
            "xmi:id": xmi_id,
            supplier: supplier_id,
          ) { yield self if block_given? }
        end

        def owned_comment(xmi_id:, body:, annotated_id: nil)
          attrs = { "xmi:type": "uml:Comment", "xmi:id": xmi_id, body: body }
          @builder.ownedComment(attrs) do
            @builder.annotatedElement("xmi:idref": annotated_id) if annotated_id
          end
        end

        def element_import(xmi_id:, imported_element_id:)
          @builder.elementImport(
            "xmi:type": "uml:ElementImport",
            "xmi:id": xmi_id,
            importedElement: imported_element_id,
          )
        end

        def profile_application(xmi_id:, applied_profile_href:)
          @builder.profileApplication(
            "xmi:type": "uml:ProfileApplication",
            "xmi:id": xmi_id,
          ) do
            @builder.appliedProfile(
              "xmi:type": "uml:Profile",
              href: applied_profile_href,
            )
          end
        end

        def slot(xmi_id:, defining_feature_id:)
          @builder.slot(
            "xmi:type": "uml:Slot",
            "xmi:id": xmi_id,
            definingFeature: defining_feature_id,
          ) { yield self if block_given? }
        end

        def opaque_expression_value(xmi_id:, body:)
          @builder.value(
            "xmi:type": "uml:OpaqueExpression",
            "xmi:id": xmi_id,
            body: body,
          )
        end

        def to_xml
          @builder.to_xml
        end

        private

        def packaged_attrs(xmi_type, xmi_id, attrs)
          result = { "xmi:type": xmi_type, "xmi:id": xmi_id }
          result[:name] = attrs[:name] if attrs[:name]
          result[:visibility] = attrs[:visibility] if attrs[:visibility]
          result[:isAbstract] = "true" if attrs[:is_abstract]
          result[:aggregation] = attrs[:aggregation] if attrs[:aggregation]
          result[:classifier] = attrs[:classifier] if attrs[:classifier]
          result[:supplier] = attrs[:supplier] if attrs[:supplier]
          result[:client] = attrs[:client] if attrs[:client]
          result
        end

        def emit_property_container(tag:, xmi_id:, name:, type:, visibility:,
                                    association:, aggregation: nil, **extra)
          attrs = { "xmi:type": "uml:Property", "xmi:id": xmi_id }
          attrs[:name] = name if name
          attrs[:visibility] = visibility if visibility
          attrs[:type] = type if type
          attrs[:association] = association if association
          attrs[:aggregation] = aggregation if aggregation
          attrs[:isStatic] = "true" if extra[:is_static]
          attrs[:isOrdered] = "true" if extra[:is_ordered]
          attrs[:isReadOnly] = "true" if extra[:is_read_only]
          @builder.public_send(tag, attrs) { yield self if block_given? }
        end
      end
    end
  end
end
