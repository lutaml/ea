# frozen_string_literal: true

require "xmi"
require "nokogiri"

module Ea
  module Transformers
    module QeaToXmi
      # Orchestrates serialization of an Ea::Qea::Database to Sparx XMI.
      #
      # Walks the package tree starting at root packages, constructing
      # xmi gem models (Xmi::Uml::UmlModel, Xmi::Uml::PackagedElement,
      # Xmi::Uml::OwnedAttribute, Xmi::Uml::OwnedEnd, etc.) from each
      # QEA row, then asks the xmi gem to render them via
      # `to_xml(use_prefix: true)` to produce Sparx XMI in the canonical
      # mixed-prefix style.
      #
      # Element-kind dispatch (Class vs Enumeration vs DataType vs Instance)
      # lives in {#build_classifier} as a single case statement. Adding a
      # new element kind = adding one branch there. Polymorphism for XMI
      # element shape lives in the xmi gem's models (xmi:type discriminator
      # on PackagedElement), not here.
      #
      # This is the FULL-FIDELITY path — no Lutaml::Uml::Document
      # intermediate. Sparx-specific concepts (multiplicities, tagged
      # values, stereotypes, primitive types, instance specifications,
      # association ends) come straight from the QEA tables.
      #
      # Phase 2 will extend the xmi gem with visibility / isAbstract /
      # classifier / aggregation attributes that the QEA database
      # contains but the xmi gem's models don't yet declare.
      class Transformer
        MODEL_NAME = "EA_Model"
        EXPORTER   = "Enterprise Architect"
        EXPORTER_VERSION = "6.5"

        RELATIONSHIP_AT_PACKAGE_LEVEL = {
          "Association" => :association,
          "Aggregation" => :association,
          "Composition" => :association,
          "Dependency"  => :dependency,
          "Usage"       => :dependency,
        }.freeze

        UNLIMITED_TOKENS = %w[* *-1 unbounded].freeze

        def initialize(database)
          @database = database
          @context  = Context.new(database: database)
        end

        # @return [String] XMI XML document
        def serialize
          strip_empty_elements(build_root.to_xml(use_prefix: true))
        end

        # The xmi gem's UML models declare `value_map: Xmi::VALUE_MAP` on every
        # child-element mapping. That VALUE_MAP is round-trip-oriented: it
        # forces empty-element emission (`<generalization/>`, `<ownedEnd/>`,
        # etc.) so the parser can preserve absence vs. emptiness on the way
        # back in. For *generation* from a QEA database, those empty elements
        # are pure noise — they bloat the output and break count-parity with
        # real Sparx XMI.
        #
        # Phase 2 will move this concern into the xmi gem by introducing a
        # generation-friendly value_map. Until then, this method strips
        # truly-empty elements (no children, no text, no attributes) from
        # the serialized output. Elements carrying attributes (e.g.
        # `<generalization general="..."/>`) are preserved.
        def strip_empty_elements(xml)
          doc = Nokogiri::XML(xml)
          removed = 1
          while removed.positive?
            removed = 0
            doc.xpath("//*[not(node()) and not(@*)]").each do |node|
              node.remove
              removed += 1
            end
          end
          doc.to_xml
        end

        private

        # ---- Top-level construction --------------------------------------

        def build_root
          ::Xmi::Sparx::Root.new(
            documentation: build_documentation,
            model: build_model,
            extension: build_extension,
          )
        end

        def build_documentation
          ::Xmi::Documentation.new(
            exporter: EXPORTER,
            exporter_version: EXPORTER_VERSION,
          )
        end

        def build_model
          ::Xmi::Uml::UmlModel.new(
            type: "uml:Model",
            name: MODEL_NAME,
            packaged_element: root_packages.map { |pkg| build_package(pkg) },
          )
        end

        def build_extension
          ::Xmi::Sparx::Extension.new(extender: EXPORTER)
        end

        def root_packages
          @database.packages
                  .select(&:root?)
                  .sort_by { |p| [p.tpos || 0, p.name.to_s] }
        end

        # ---- Package tree ------------------------------------------------

        def build_package(pkg)
          ::Xmi::Uml::PackagedElement.new(
            type: "uml:Package",
            id: @context.xmi_id_for(pkg, prefix: "EAPK"),
            name: pkg.name,
            owned_comment: package_comments(pkg),
            packaged_element: package_children(pkg),
          )
        end

        def package_children(pkg)
          [
            *subpackages(pkg),
            *classifier_objects(pkg),
            *package_level_relationships(pkg),
          ].compact
        end

        def subpackages(pkg)
          sorted_by_position(@context.child_packages(pkg.package_id))
            .map { |sub| build_package(sub) }
        end

        def classifier_objects(pkg)
          classifiers_in(pkg).map { |obj| build_classifier(obj) }.compact
        end

        # Connectors owned by this package: connectors whose start_object is
        # a classifier in this package and whose type is a package-level
        # relationship (Association / Dependency). Generalization and
        # Realization are emitted inside the classifier itself.
        def package_level_relationships(pkg)
          emitted = Set.new
          classifiers_in(pkg).flat_map do |obj|
            @context.connectors_starting_at(obj.ea_object_id).filter_map do |conn|
              key = RELATIONSHIP_AT_PACKAGE_LEVEL[conn.connector_type]
              next nil unless key
              next nil unless emitted.add?(conn.connector_id)

              build_package_relationship(key, conn)
            end
          end
        end

        def build_package_relationship(kind, conn)
          case kind
          when :association then build_association(conn)
          when :dependency  then build_dependency(conn)
          end
        end

        def package_comments(pkg)
          notes_in(pkg).map { |obj| build_comment(obj) }
        end

        # ---- Classifier objects (Class / Enumeration / DataType / Instance)

        def build_classifier(obj)
          kind = obj.transformer_type || obj.object_type&.downcase&.to_sym
          case kind
          when :class        then build_class(obj)
          when :enumeration  then build_enumeration(obj)
          when :data_type    then build_data_type(obj)
          when :instance     then build_instance(obj)
          end
        end

        def build_class(obj)
          ::Xmi::Uml::PackagedElement.new(
            type: class_xmi_type(obj),
            id: @context.xmi_id_for(obj),
            name: obj.name,
            generalization: generalizations_for(obj),
            owned_attribute: attributes_for(obj),
            owned_operation: operations_for(obj),
          )
        end

        def build_enumeration(obj)
          ::Xmi::Uml::PackagedElement.new(
            type: "uml:Enumeration",
            id: @context.xmi_id_for(obj),
            name: obj.name,
            owned_literal: enum_literals(obj),
          )
        end

        def build_data_type(obj)
          ::Xmi::Uml::PackagedElement.new(
            type: primitive?(obj) ? "uml:PrimitiveType" : "uml:DataType",
            id: @context.xmi_id_for(obj),
            name: obj.name,
            owned_attribute: attributes_for(obj),
            owned_operation: operations_for(obj),
          )
        end

        def build_instance(obj)
          ::Xmi::Uml::PackagedElement.new(
            type: "uml:InstanceSpecification",
            id: @context.xmi_id_for(obj),
            name: obj.name,
          )
        end

        def build_comment(obj)
          ::Xmi::Uml::OwnedComment.new(
            type: "uml:Comment",
            id: @context.xmi_id_for(obj),
            body_element: obj.note || obj.name || "",
          )
        end

        # ---- Children of a classifier ------------------------------------

        def generalizations_for(obj)
          inheritance_connectors(obj, "Generalization")
            .filter_map { |conn| build_generalization(conn) }
        end

        def attributes_for(obj)
          sorted_by_position(@context.attributes_for(obj.ea_object_id))
            .map { |attr| build_attribute(attr) }
        end

        def operations_for(obj)
          sorted_by_position(@context.operations_for(obj.ea_object_id))
            .map { |op| build_operation(op) }
        end

        def enum_literals(obj)
          sorted_by_position(@context.attributes_for(obj.ea_object_id))
            .map { |attr| build_owned_literal(attr) }
        end

        # ---- Leaf element builders --------------------------------------

        def build_attribute(attr)
          ::Xmi::Uml::OwnedAttribute.new(
            type: "uml:Property",
            id: @context.xmi_id_for(attr),
            name: attr.name,
            uml_type: type_reference_model(attr.type, attr.classifier),
            upper_value: upper_value_for(attr),
            lower_value: lower_value_for(attr),
          )
        end

        def build_operation(op)
          ::Xmi::Uml::OwnedOperation.new(
            id: @context.xmi_id_for(op),
            name: op.name,
            owned_parameter: operation_parameters(op),
          )
        end

        def build_owned_literal(attr)
          ::Xmi::Uml::OwnedLiteral.new(
            type: "uml:EnumerationLiteral",
            id: @context.xmi_id_for(attr),
            name: attr.name,
          )
        end

        def build_generalization(conn)
          parent = @context.object_by_id(conn.end_object_id)
          return nil unless parent

          ::Xmi::Uml::AssociationGeneralization.new(
            type: "uml:Generalization",
            id: @context.xmi_id_for(conn),
            general: @context.xmi_id_for(parent),
          )
        end

        def build_dependency(conn)
          client = @context.object_by_id(conn.start_object_id)
          supplier = @context.object_by_id(conn.end_object_id)
          return nil unless client && supplier

          ::Xmi::Uml::PackagedElement.new(
            type: "uml:Dependency",
            id: @context.xmi_id_for(conn),
            client: @context.xmi_id_for(client),
            supplier: @context.xmi_id_for(supplier),
          )
        end

        def build_association(conn)
          dest_end = build_association_end(conn, side: :destination)
          src_end  = build_association_end(conn, side: :source)

          ::Xmi::Uml::PackagedElement.new(
            type: "uml:Association",
            id: @context.xmi_id_for(conn),
            name: conn.name,
            member_ends: [
              ::Xmi::Uml::MemberEnd.new(idref: dest_end[:xmi_id]),
              ::Xmi::Uml::MemberEnd.new(idref: src_end[:xmi_id]),
            ],
            owned_end: [dest_end[:model], src_end[:model]],
          )
        end

        def build_association_end(conn, side:)
          end_id = @context.end_xmi_id_for(@context.xmi_id_for(conn), side: side)
          target_id = side == :source ? conn.start_object_id : conn.end_object_id
          target_obj = @context.object_by_id(target_id)
          target_ref = target_obj ? @context.xmi_id_for(target_obj) : nil
          bounds = parse_cardinality(cardinality_for(conn, side))

          model = ::Xmi::Uml::OwnedEnd.new(
            type: "uml:Property",
            id: end_id,
            name: role_name_for(conn, side),
            association: @context.xmi_id_for(conn),
            uml_type: target_ref ? ::Xmi::Uml::Type.new(idref: target_ref) : nil,
            upper_value: build_upper_value(bounds && bounds[:upper], "mult-#{conn.connector_id}-#{side}-upper"),
            lower_value: build_lower_value(bounds && bounds[:lower], "mult-#{conn.connector_id}-#{side}-lower"),
          )

          { xmi_id: end_id, model: model }
        end

        # ---- Multiplicity helpers ---------------------------------------

        def upper_value_for(attr)
          return nil if attr.upperbound.nil? || attr.upperbound.to_s.empty?

          build_upper_value(normalize_upper(attr.upperbound), "mult-attr-#{attr.id}-upper")
        end

        def lower_value_for(attr)
          return nil if attr.lowerbound.nil? || attr.lowerbound.to_s.empty?

          build_lower_value(normalize_lower(attr.lowerbound), "mult-attr-#{attr.id}-lower")
        end

        def build_upper_value(value, seed)
          return nil if value.nil?

          ::Xmi::Uml::UpperValue.new(
            type: "uml:LiteralUnlimitedNatural",
            id: @context.id_allocator.for_multiplicity(:upper, seed: seed),
            value: value,
          )
        end

        def build_lower_value(value, seed)
          return nil if value.nil?

          ::Xmi::Uml::LowerValue.new(
            type: "uml:LiteralInteger",
            id: @context.id_allocator.for_multiplicity(:lower, seed: seed),
            value: value,
          )
        end

        # ---- Operation parameters ---------------------------------------

        def operation_parameters(op)
          params = sorted_by_position(@context.params_for_operation(op.operationid))
            .reject(&:return?)
            .map { |p| build_owned_parameter(p) }
          params << build_return_parameter(op) if op.type && !op.type.empty?
          params
        end

        def build_owned_parameter(param)
          ::Xmi::Uml::OwnedParameter.new(
            id: @context.xmi_id_for(param),
            name: param.name,
            direction: param.kind&.downcase,
          )
        end

        def build_return_parameter(op)
          ::Xmi::Uml::OwnedParameter.new(
            id: @context.id_allocator.allocate(
              prefix: "RT",
              seed: "return-#{op.operationid}",
            ),
            name: "return",
            direction: "return",
          )
        end

        # ---- Shared helpers ---------------------------------------------

        def class_xmi_type(obj)
          obj.interface? ? "uml:Interface" : "uml:Class"
        end

        def inheritance_connectors(obj, type)
          @context.connectors_for(obj.ea_object_id).select do |conn|
            conn.start_object_id == obj.ea_object_id && conn.connector_type == type
          end
        end

        def classifiers_in(pkg)
          @context.objects_in_package(pkg.package_id)
                  .reject { |o| note?(o) || package_object?(o) }
        end

        def notes_in(pkg)
          @context.objects_in_package(pkg.package_id).select { |o| note?(o) }
        end

        def note?(obj)
          obj.object_type == "Note" || obj.object_type == "Text"
        end

        def package_object?(obj)
          obj.object_type == "Package"
        end

        def sorted_by_position(records)
          records.sort_by { |r| [r.sort_position, r.name.to_s] }
        end

        def primitive?(obj)
          obj.object_type == "PrimitiveType" ||
            (obj.gentype == "Java" && obj.stereotype_is?("primitive"))
        end

        def type_reference(type_name, classifier_guid)
          return nil if type_name.nil? || type_name.empty?

          if classifier_guid
            GuidFormat.ea_guid_to_xmi_id(classifier_guid)
          else
            "EAnone_#{type_name}"
          end
        end

        def type_reference_model(type_name, classifier_guid)
          ref = type_reference(type_name, classifier_guid)
          ref ? ::Xmi::Uml::Type.new(idref: ref) : nil
        end

        def cardinality_for(conn, side)
          side == :source ? conn.sourcecard : conn.destcard
        end

        def role_name_for(conn, side)
          side == :source ? conn.sourcerole : conn.destrole
        end

        def normalize_upper(raw)
          UNLIMITED_TOKENS.include?(raw.to_s.strip.downcase) ? "-1" : raw.to_s
        end

        def normalize_lower(raw)
          raw.to_s
        end

        # EA cardinality format: ".." separates bounds, e.g. "1..*", "0..1".
        # Single number means exact (e.g. "1" → lower=upper=1).
        def parse_cardinality(raw)
          return nil if raw.nil? || raw.to_s.empty?

          stripped = raw.to_s.strip
          return parse_range(stripped) if stripped.include?("..")

          single = normalize_bound(stripped)
          { lower: single, upper: single }
        end

        def parse_range(stripped)
          lower, upper = stripped.split("..", 2)
          { lower: normalize_bound(lower), upper: normalize_bound(upper) }
        end

        def normalize_bound(token)
          return "-1" if token.nil? || token.strip.empty?
          return "-1" if token.strip == "*"

          token.strip
        end
      end
    end
  end
end