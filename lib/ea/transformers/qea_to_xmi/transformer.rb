# frozen_string_literal: true

require "xmi"

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
      # mixed-prefix style. The serialized output is run through
      # {XmlSanitizer} to strip truly-empty elements that the xmi gem's
      # round-trip-oriented VALUE_MAP emits but Sparx XMI does not.
      #
      # Element-kind dispatch (Class vs Enumeration vs DataType vs
      # Instance) is registry-driven — see CLASSIFIER_BUILDERS. Adding
      # a new kind = adding one entry to that hash, no method change.
      # Polymorphism for XMI element shape lives in the xmi gem's models
      # (xmi:type discriminator on PackagedElement), not here.
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

        # OCP registry: maps EaObject#transformer_type to the builder
        # that constructs the corresponding Xmi::Uml element. To add a
        # new element kind (Signal, Interface, ...), append one entry
        # here — `build_classifier` requires no edit.
        #
        # Builders are lambdas evaluated via `instance_exec`, so they
        # run inside the Transformer instance and can call its private
        # helpers without `send`/`public_send` dispatch.
        CLASSIFIER_BUILDERS = {
          class:       ->(obj) { build_class(obj) },
          enumeration: ->(obj) { build_enumeration(obj) },
          data_type:   ->(obj) { build_data_type(obj) },
          instance:    ->(obj) { build_instance(obj) },
        }.freeze

        def initialize(database)
          @database = database
          @context  = Context.new(database: database)
        end

        # @return [String] XMI XML document
        #
        # The xmi gem's VALUE_MAP is generation-friendly
        # (`to: { nil: :omitted, ... }`), so empty collections and
        # nil-valued attributes are skipped at the source. No
        # post-processing pass is needed — the prior XmlSanitizer
        # workaround (TODO 21 §1) has been removed.
        def serialize
          build_root.to_xml(use_prefix: true)
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

        # ---- Classifier dispatch (OCP registry) --------------------------

        def build_classifier(obj)
          kind = obj.transformer_type || obj.object_type&.downcase&.to_sym
          builder = CLASSIFIER_BUILDERS[kind]
          return nil unless builder

          instance_exec(obj, &builder)
        end

        def build_class(obj)
          ::Xmi::Uml::PackagedElement.new(
            type: class_xmi_type(obj),
            id: @context.xmi_id_for(obj),
            name: obj.name,
            visibility: Visibility.from_scope(obj.scope),
            is_abstract: Visibility.boolean_from_flag(obj.abstract),
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
            visibility: Visibility.from_scope(obj.scope),
            owned_literal: enum_literals(obj),
          )
        end

        def build_data_type(obj)
          ::Xmi::Uml::PackagedElement.new(
            type: primitive?(obj) ? "uml:PrimitiveType" : "uml:DataType",
            id: @context.xmi_id_for(obj),
            name: obj.name,
            visibility: Visibility.from_scope(obj.scope),
            owned_attribute: attributes_for(obj),
            owned_operation: operations_for(obj),
          )
        end

        def build_instance(obj)
          ::Xmi::Uml::PackagedElement.new(
            type: "uml:InstanceSpecification",
            id: @context.xmi_id_for(obj),
            name: obj.name,
            visibility: Visibility.from_scope(obj.scope),
            classifier: classifier_ref_for(obj),
            slot: slots_for(obj),
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
          parent_guid = parent_guid_for_attribute(attr)
          ::Xmi::Uml::OwnedAttribute.new(
            type: "uml:Property",
            id: @context.xmi_id_for(attr),
            name: attr.name,
            visibility: Visibility.from_scope(attr.scope),
            is_static: Visibility.boolean_from_flag(attr.isstatic),
            is_ordered: Visibility.boolean_from_flag(attr.isordered),
            is_derived: Visibility.boolean_from_flag(attr.derived),
            uml_type: type_reference_model(attr.type, attr.classifier),
            upper_value: build_upper_value(attr.upperbound, seed: "mult-attr-#{attr.id}-upper", parent_guid: parent_guid),
            lower_value: build_lower_value(attr.lowerbound, seed: "mult-attr-#{attr.id}-lower", parent_guid: parent_guid),
          )
        end

        def build_operation(op)
          ::Xmi::Uml::OwnedOperation.new(
            id: @context.xmi_id_for(op),
            name: op.name,
            visibility: Visibility.from_scope(op.scope),
            is_static: Visibility.boolean_from_flag(op.isstatic),
            is_abstract: Visibility.boolean_from_flag(op.abstract),
            is_query: Visibility.boolean_from_flag(op.pure),
            concurrency: op.concurrency&.downcase,
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

        # Sparx serialisation order for `uml:Association` is
        # destination member-end first, source member-end second.
        # Reordering these breaks round-trip fidelity with Sparx EA
        # (the importer treats the first member-end as the destination
        # role). Don't reorder without verifying against a Sparx
        # round-trip fixture.
        def build_association(conn)
          dest_end = build_association_end(conn, side: :destination)
          src_end  = build_association_end(conn, side: :source)

          ::Xmi::Uml::PackagedElement.new(
            type: "uml:Association",
            id: @context.xmi_id_for(conn),
            name: conn.name,
            member_ends: [
              ::Xmi::Uml::MemberEnd.new(idref: dest_end.xmi_id),
              ::Xmi::Uml::MemberEnd.new(idref: src_end.xmi_id),
            ],
            owned_end: [dest_end.model, src_end.model],
          )
        end

        def build_association_end(conn, side:)
          end_id = @context.end_xmi_id_for(@context.xmi_id_for(conn), side: side)
          target_id = side == :source ? conn.start_object_id : conn.end_object_id
          target_obj = @context.object_by_id(target_id)
          target_ref = target_obj ? @context.xmi_id_for(target_obj) : nil
          bounds = Cardinality.parse(cardinality_for(conn, side))
          containment = containment_for(conn, side)

          model = ::Xmi::Uml::OwnedEnd.new(
            type: "uml:Property",
            id: end_id,
            name: role_name_for(conn, side),
            visibility: visibility_for_end(conn, side),
            aggregation: Visibility.aggregation_from_containment(containment),
            association: @context.xmi_id_for(conn),
            uml_type: target_ref ? ::Xmi::Uml::Type.new(idref: target_ref) : nil,
            upper_value: build_upper_value(bounds[:upper], seed: "mult-#{conn.connector_id}-#{side}-upper", parent_guid: conn.ea_guid),
            lower_value: build_lower_value(bounds[:lower], seed: "mult-#{conn.connector_id}-#{side}-lower", parent_guid: conn.ea_guid),
          )

          AssociationEnd.new(end_id, model)
        end

        # ---- Multiplicity helpers ---------------------------------------

        # Always emit both bounds — UML defaults (lower=0, upper=-1) are
        # used when the EA field is blank. Matches real Sparx XMI, which
        # never omits `<upperValue>`/`<lowerValue>` on a Property.
        def build_upper_value(raw, seed:, parent_guid:)
          ::Xmi::Uml::UpperValue.new(
            type: "uml:LiteralUnlimitedNatural",
            id: @context.id_allocator.allocate(
              prefix: IdAllocator::LITERAL_INTEGER,
              seed: seed,
              parent_guid: parent_guid,
            ),
            value: Cardinality.normalize_upper(raw),
          )
        end

        def build_lower_value(raw, seed:, parent_guid:)
          ::Xmi::Uml::LowerValue.new(
            type: "uml:LiteralInteger",
            id: @context.id_allocator.allocate(
              prefix: IdAllocator::LITERAL_INTEGER,
              seed: seed,
              parent_guid: parent_guid,
            ),
            value: Cardinality.normalize_lower(raw),
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
              prefix: IdAllocator::RETURN_PARAMETER,
              seed: "return-#{op.operationid}",
              parent_guid: op.ea_guid,
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

        def containment_for(conn, side)
          side == :source ? conn.sourcecontainment : conn.destcontainment
        end

        # EA's t_connector does not expose per-end visibility (the
        # source/dest scopes are stored only on the role's target
        # object, which has its own visibility). Leave ownedEnd
        # visibility unset unless a future schema change exposes it.
        def visibility_for_end(_conn, _side)
          nil
        end

        # The owning element for an attribute's synthesised IDs is the
        # attribute's classifier (parent object), not the attribute
        # itself — Sparx encodes the parent class GUID in the suffix.
        def parent_guid_for_attribute(attr)
          parent = @context.object_by_id(attr.ea_object_id)
          parent&.ea_guid
        end

        # InstanceSpecification classifier reference. EA stores this
        # in t_object.pdata1 as the classifier's ea_object_id.
        def classifier_ref_for(obj)
          classifier_id = obj.pdata1&.to_i
          return nil if classifier_id.nil? || classifier_id.zero?

          classifier = @context.object_by_id(classifier_id)
          classifier ? @context.xmi_id_for(classifier) : nil
        end

        # InstanceSpecification slots (RunState / attribute values).
        # Phase 1 emits no slots; Phase 2 will walk t_object.RunState
        # and t_attribute for instance value specifications.
        def slots_for(obj)
          []
        end
      end
    end
  end
end
