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
        BUILD_ID = "1624"

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
          signal:      ->(obj) { build_class(obj, xmi_type: "uml:Signal") },
          instance:    ->(obj) { build_instance(obj) },
          association_element: ->(obj) { build_association_element(obj) },
        }.freeze

        # What each builder in CLASSIFIER_BUILDERS actually emits, keyed
        # by the same symbols. Every builder must appear here: a kind
        # left out silently loses its attribute bounds or its nested
        # children — wrong XML, no exception — so the spec asserts these
        # keys match CLASSIFIER_BUILDERS exactly.
        #
        # `:owned_attribute` — the builder emits `<ownedAttribute>` and so
        #   preallocates attribute bound IDs. Enumerations emit literals
        #   (never bounds) and instances emit slots.
        # `:nested_classifier` — the builder walks children, so a kind
        #   listed here can adopt an object that carries a parentid.
        #   `build_class` is the only builder that walks children.
        CLASSIFIER_CAPABILITIES = {
          class: %i[owned_attribute nested_classifier],
          signal: %i[owned_attribute nested_classifier],
          data_type: %i[owned_attribute],
          enumeration: [],
          instance: [],
          association_element: []
        }.freeze

        def initialize(database, mdg_registry: nil)
          @database = database
          @mdg_registry = mdg_registry
          @context = Context.new(database: database)
        end

        # @return [String] XMI XML document
        #
        # The xmi gem's VALUE_MAP is generation-friendly
        # (`to: { nil: :omitted, ... }`), so empty collections and
        # nil-valued attributes are skipped at the source. No
        # post-processing pass is needed — the prior XmlSanitizer
        # workaround (TODO 21 §1) has been removed.
        # Serialize to XMI XML.
        #
        # Default produces model tree only (parseable by the xmi gem's
        # Sparx parser for round-trip). Pass `with_extensions: true` to
        # also emit EA-specific `<connectors>` and `<diagrams>` sections
        # inside `<xmi:Extension>`. Those use post-processing string
        # injection that the xmi gem's parser doesn't model, so the
        # output is NOT round-trippable when extensions are included.
        #
        # @param with_extensions [Boolean]
        # @return [String] XMI XML
        def serialize(with_extensions: true)
          xml = build_root.to_xml(use_prefix: true)
          xml = normalize_namespaces(xml)
          xml = plain_parameter_type(xml)
          with_extensions ? inject_extension_content(xml) : xml
        end

        # EA writes a return parameter's type unprefixed:
        # `<ownedParameter … type="EAnone_void"/>`. Its reference export
        # carries 12 of these and no `xmi:type` on ownedParameter at all.
        #
        # `xmi:type` is the XMI metaclass discriminator; `type` is the
        # classifier reference. Two different attributes — but
        # lutaml-model matches by local name and collapses them into one
        # slot, so the xmi gem can only emit one of them. It keeps the
        # namespaced form, which is right for general UML XMI, and
        # rewriting that in the shared model would break round-tripping
        # for every non-Sparx consumer. Restoring the reference EA
        # actually writes is this exporter's job, so it happens here.
        #
        # Scoped to ownedParameter: no other element wants it. Walks
        # complete name="value" pairs rather than scanning the tag as
        # text — a parameter name is free text out of EA and may itself
        # contain the literal `xmi:type=`, which a raw substitution
        # would happily rewrite inside the quotes.
        ATTRIBUTE_PAIR = /([A-Za-z_][\w:.-]*)=("[^"]*")/

        def plain_parameter_type(xml)
          xml.gsub(/<ownedParameter\b[^>]*?>/m) do |tag|
            tag.gsub(ATTRIBUTE_PAIR) do
              name = Regexp.last_match(1)
              name == "xmi:type" ? %(type=#{Regexp.last_match(2)}) : Regexp.last_match(0)
            end
          end
        end

        # EA's reference XMI uses the 2011-07-01 XMI/UML namespace URIs;
        # the xmi gem's Root model hard-codes 2013-10-01. Post-process
        # the serialized XML to match EA's namespace version. This is a
        # targeted string replacement on the xmlns declarations only,
        # not a semantic change.
        def normalize_namespaces(xml)
          xml.gsub("http://www.omg.org/spec/XMI/20131001",
                   "http://www.omg.org/spec/XMI/20110701")
             .gsub("http://www.omg.org/spec/UML/20131001/UMLDI",
                   "http://www.omg.org/spec/UML/20110701/UMLDI")
             .gsub("http://www.omg.org/spec/UML/20131001/UMLDC",
                   "http://www.omg.org/spec/UML/20110701/UMLDC")
             .gsub("http://www.omg.org/spec/UML/20131001",
                   "http://www.omg.org/spec/UML/20110701")
        end

        # Injects EA-specific extension content (elements, connectors,
        # diagrams) into the serialized XMI. The xmi gem's Extension
        # type is modeled but doesn't declare these children. We
        # post-process the serialized XML to insert them inside the
        # existing `<xmi:Extension>` element.
        #
        # Delegated to {ExtensionSerializer} — this class only handles
        # the string substitution mechanics.
        def inject_extension_content(xml)
          content = ExtensionSerializer.new(@database, @context).call
          return xml if content.empty?

          if xml.include?("<xmi:Extension")
            xml.sub(%r{<xmi:Extension ([^>]+)>\s*</xmi:Extension>},
                   "<xmi:Extension \\1>\n#{content}\n\t</xmi:Extension>")
               .sub(/<xmi:Extension ([^>]+)\/>/,
                    "<xmi:Extension \\1>\n#{content}\n\t</xmi:Extension>")
          else
            xml
          end
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
            exporter_id: BUILD_ID,
          )
        end

        def build_model
          ::Xmi::Uml::UmlModel.new(
            type: "uml:Model",
            name: MODEL_NAME,
            packaged_element: root_packages.map { |pkg| build_package(pkg) } + profile_elements,
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

        # MDG stereotype definitions to include in the model tree.
        # Empty when no MDG registry is wired. Each registered MDG
        # contributes its stereotypes and extension relationships.
        def profile_elements
          ProfileSerializer.new(@mdg_registry).call
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
          @context.sorted_by_position(@context.child_packages(pkg.package_id))
                  .map { |sub| build_package(sub) }
        end

        # EA emits a package's own classifiers first, then the children
        # nobody adopted. The global LI counter follows that order.
        def classifier_objects(pkg)
          top_level, orphaned = package_level_classifiers(pkg)
                                .partition { |obj| obj.parentid.to_i.zero? }
          (top_level + orphaned).filter_map { |obj| build_classifier_with_bounds(obj) }
        end

        # Everything EA leaves at package level: an object stays here
        # unless a classifier in the same package actually adopts it as
        # a nestedClassifier. A child of an enumeration, of an
        # instance, of a type we don't build, of a parent in another
        # package, or of one that isn't there at all has no adopter.
        #
        # Adoption is decided from the package's own contents, never
        # from what the walk has emitted so far — a child can sort
        # before its own parent, and asking a set that the walk is
        # still filling would emit that child twice.
        def package_level_classifiers(pkg)
          buildable_objects_in(pkg).reject { |obj| adopted?(obj) }
        end

        # A parent adopts a child only if it is a nesting kind in the
        # same package AND the ParentID chain above the child actually
        # terminates. A corrupt model can point an object at itself or
        # round a cycle; leaving those adopted would drop them from the
        # export, since the parent that owes them an emission is never
        # reached. Shared with nested_classifiers_under so the two
        # cannot disagree about who owns a child.
        def adopted?(obj)
          parent = nesting_parent_of(obj)
          !parent.nil? && !cyclic_ancestry?(obj)
        end

        def nesting_parent_of(obj)
          parent_id = obj.parentid.to_i
          return nil unless parent_id.positive?

          parent = @context.object_by_id(parent_id)
          return nil unless parent && parent.package_id == obj.package_id
          return nil unless nests_classifiers?(parent)

          parent
        end

        def cyclic_ancestry?(obj)
          seen = Set[obj.ea_object_id]
          current = obj
          while (current = nesting_parent_of(current))
            return true unless seen.add?(current.ea_object_id)
          end
          false
        end

        # EA's class-centric LI allocation: attribute bounds first (name
        # order), then the classifier itself, then the association-end
        # bounds anchored here. The memoized allocator lets later
        # builders reuse these IDs.
        def build_classifier_with_bounds(obj)
          preallocate_attribute_bounds(obj)
          element = build_classifier(obj)
          preallocate_end_bounds(obj)
          element
        end

        # EA allocates a classifier's attribute LI bounds in attribute
        # NAME order, while the document emits attributes in Pos order.
        # Pre-allocating here (memoized) makes the later Pos-ordered
        # build reuse the name-ordered counters. Only owners that go on
        # to emit ownedAttribute take counters — an enumeration's
        # literals never carry bounds.
        def preallocate_attribute_bounds(obj)
          return unless emits_attributes?(obj)

          @context.attributes_for(obj.ea_object_id)
                  .sort_by { |a| a.name.to_s }
                  .each { |attr| build_attribute_bounds(attr) }
        end

        # Lower before upper — the global LI counter follows this order.
        # @return [Array(Xmi::Uml::LowerValue, Xmi::Uml::UpperValue)]
        def build_attribute_bounds(attr)
          attr_id = @context.xmi_id_for(attr)
          bounds = Cardinality.attribute_bounds(attr.lowerbound, attr.upperbound)
          [build_lower_value(bounds[:lower],
                             seed: "mult-attr-#{attr.id}-lower", owner_id: attr_id),
           build_upper_value(bounds[:upper],
                             seed: "mult-attr-#{attr.id}-upper", owner_id: attr_id)]
        end

        # EA's global LI counter is allocated class-centrically, not in
        # document order: after a classifier's attribute bounds come the
        # association-end bounds whose OPPOSITE endpoint is that
        # classifier (dst ends of connectors starting here, src ends of
        # connectors ending here). The memoized allocator lets the
        # Association element reuse these IDs when it is built later.
        def preallocate_end_bounds(obj)
          association_ends_anchored_at(obj)
            .each { |conn, side| build_association_end(conn, side: side) }
        end

        # The ends anchored at a classifier, ordered by connector GUID
        # (ascending string order — the only key that fits every tied
        # case in the reference exports; names, connector ids and
        # opposite-endpoint ids all contradict at least one).
        def association_ends_anchored_at(obj)
          @context.connectors_for(obj.ea_object_id)
                  .flat_map { |conn| anchored_end_sides(conn, obj.ea_object_id) }
                  .sort_by { |conn, side| [conn.ea_guid.to_s, side == :destination ? 0 : 1] }
        end

        def anchored_end_sides(conn, object_id)
          return [] unless RELATIONSHIP_AT_PACKAGE_LEVEL[conn.connector_type] == :association

          pairs = []
          pairs << [conn, :destination] if conn.start_object_id == object_id
          pairs << [conn, :source] if conn.end_object_id == object_id
          pairs
        end

        # Connectors owned by this package: connectors whose start_object is
        # a classifier in this package and whose type is a package-level
        # relationship (Association / Dependency). Generalization and
        # Realization are emitted inside the classifier itself.
        def package_level_relationships(pkg)
          emitted = Set.new
          relationship_sources_in(pkg).flat_map do |obj|
            @context.connectors_starting_at(obj.ea_object_id).filter_map do |conn|
              key = RELATIONSHIP_AT_PACKAGE_LEVEL[conn.connector_type]
              next nil unless key
              next nil unless emitted.add?(conn.connector_id)

              build_package_relationship(key, conn)
            end
          end
        end

        # Relationship discovery must also see Package objects —
        # package-to-package Dependency connectors hang off them even
        # though they never emit as classifiers.
        def relationship_sources_in(pkg)
          @context.objects_in_package(pkg.package_id).reject { |o| note?(o) }
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
          builder = CLASSIFIER_BUILDERS[obj.transformer_type]
          return nil unless builder

          instance_exec(obj, &builder)
        end

        # Objects that build no classifier at all (a Component parent, a
        # Note) reach these predicates too, and answer no to both.
        def capabilities_of(obj)
          CLASSIFIER_CAPABILITIES.fetch(obj.transformer_type, [])
        end

        def emits_attributes?(obj)
          capabilities_of(obj).include?(:owned_attribute)
        end

        def nests_classifiers?(obj)
          capabilities_of(obj).include?(:nested_classifier)
        end

        def build_class(obj, xmi_type: nil)
          ::Xmi::Uml::PackagedElement.new(
            type: xmi_type || class_xmi_type(obj),
            id: @context.xmi_id_for(obj),
            name: obj.name,
            visibility: Visibility.from_scope(obj.scope),
            is_abstract: Visibility.boolean_from_flag(obj.abstract),
            generalization: generalizations_for(obj),
            interface_realization: interface_realizations_for(obj),
            owned_attribute: attributes_for(obj),
            owned_operation: operations_for(obj),
            nested_classifier: nested_children_for(obj),
          )
        end

        # Recursive: nested children carry their own nested children,
        # walked with the same class-centric bound preallocation.
        def nested_children_for(obj)
          nested_classifiers_under(obj).filter_map { |child| build_classifier_with_bounds(child) }
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

        # EA stores some associations as t_object rows. Its export
        # emits them bare — id and name only, no ownedEnds and no
        # visibility. The connector-backed associations
        # (build_association) are a separate path.
        def build_association_element(obj)
          ::Xmi::Uml::PackagedElement.new(type: "uml:Association", id: @context.xmi_id_for(obj),
                                          name: obj.name)
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

        # Realization connectors point from a Class (client) to an
        # Interface (supplier). Sparx's strict OMG output emits these
        # as `<interfaceRealization>` children of the client class
        # rather than as package-level `<packagedElement type=
        # "uml:Realization">`. We do the same.
        def interface_realizations_for(obj)
          realization_connectors(obj).filter_map { |conn| build_interface_realization(conn) }
        end

        def attributes_for(obj)
          @context.sorted_by_position(@context.attributes_for(obj.ea_object_id))
                  .map { |attr| build_attribute(attr) }
        end

        def operations_for(obj)
          @context.sorted_by_position(@context.operations_for(obj.ea_object_id))
                  .map { |op| build_operation(op) }
        end

        def enum_literals(obj)
          @context.sorted_by_position(@context.attributes_for(obj.ea_object_id))
                  .map { |attr| build_owned_literal(attr) }
        end

        # ---- Leaf element builders --------------------------------------

        def build_attribute(attr)
          # An attribute always carries both bounds; association ends
          # check their single card field instead and stay bare when it
          # is blank.
          lower, upper = build_attribute_bounds(attr)
          ::Xmi::Uml::OwnedAttribute.new(
            type: "uml:Property",
            id: @context.xmi_id_for(attr),
            name: attr.name,
            visibility: Visibility.from_scope(attr.scope),
            is_static: Visibility.boolean_from_flag(attr.isstatic),
            is_ordered: Visibility.boolean_from_flag(attr.isordered),
            is_derived: Visibility.boolean_from_flag(attr.derived),
            uml_type: type_reference_model(attr.type, attr.classifier),
            upper_value: upper,
            lower_value: lower,
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
            concurrency: normalize_concurrency(op.concurrency),
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

        def build_interface_realization(conn)
          client = @context.object_by_id(conn.start_object_id)
          supplier = @context.object_by_id(conn.end_object_id)
          return nil unless client && supplier

          supplier_ref = @context.xmi_id_for(supplier)
          ::Xmi::Uml::InterfaceRealization.new(
            type: "uml:InterfaceRealization", id: @context.xmi_id_for(conn),
            name: conn.name, client: @context.xmi_id_for(client),
            supplier: supplier_ref, contract: supplier_ref
          )
        end

        def build_dependency(conn)
          client = dependency_endpoint_ref(conn.start_object_id)
          supplier = dependency_endpoint_ref(conn.end_object_id)
          return nil unless client && supplier

          ::Xmi::Uml::PackagedElement.new(
            type: "uml:Dependency",
            id: @context.xmi_id_for(conn),
            client: client,
            supplier: supplier,
          )
        end

        # Package-object endpoints resolve to their t_package via PDATA1
        # and reference it as EAPK_ (matching EA); everything else keeps
        # its own EAID_ reference.
        def dependency_endpoint_ref(object_id)
          obj = @context.object_by_id(object_id)
          return nil unless obj
          return @context.xmi_id_for(obj) unless package_object?(obj)

          pkg = @database.find_package(obj.pdata1.to_i)
          pkg && @context.xmi_id_for(pkg, prefix: "EAPK")
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
          containment = containment_for(conn, side)
          # EA emits lower/upper only when the end's cardinality is set —
          # a blank card gets a bare ownedEnd. Allocation order is lower
          # before upper, with the END's id (EAID_dst…/EAID_src…) as the
          # tail source.
          raw_card = cardinality_for(conn, side)
          lower = upper = nil
          unless raw_card.to_s.strip.empty?
            bounds = Cardinality.parse(raw_card)
            lower = build_lower_value(bounds[:lower], seed: "mult-#{conn.connector_id}-#{side}-lower", owner_id: end_id)
            upper = build_upper_value(bounds[:upper], seed: "mult-#{conn.connector_id}-#{side}-upper", owner_id: end_id)
          end

          model = ::Xmi::Uml::OwnedEnd.new(
            type: "uml:Property",
            id: end_id,
            name: role_name_for(conn, side),
            visibility: visibility_for_end(conn, side),
            aggregation: Visibility.aggregation_from_containment(containment),
            association: @context.xmi_id_for(conn),
            uml_type: target_ref ? ::Xmi::Uml::Type.new(idref: target_ref) : nil,
            upper_value: upper,
            lower_value: lower,
          )

          AssociationEnd.new(end_id, model)
        end

        # ---- Multiplicity helpers ---------------------------------------

        # Callers emit bounds only when the EA cardinality field is set —
        # EA's reference exports omit `<upperValue>`/`<lowerValue>`
        # entirely on ends whose card is blank.
        def build_upper_value(raw, seed:, owner_id:)
          ::Xmi::Uml::UpperValue.new(
            type: "uml:LiteralUnlimitedNatural",
            id: @context.id_allocator.allocate(
              prefix: IdAllocator::LITERAL_INTEGER,
              seed: seed,
              owner_id: owner_id,
            ),
            value: Cardinality.normalize_upper(raw),
          )
        end

        def build_lower_value(raw, seed:, owner_id:)
          ::Xmi::Uml::LowerValue.new(
            type: "uml:LiteralInteger",
            id: @context.id_allocator.allocate(
              prefix: IdAllocator::LITERAL_INTEGER,
              seed: seed,
              owner_id: owner_id,
            ),
            value: Cardinality.normalize_lower(raw),
          )
        end

        # ---- Operation parameters ---------------------------------------

        def operation_parameters(op)
          params = @context.params_for_operation(op.operationid)
            .reject(&:return?)
            .map { |p| build_owned_parameter(p) }
          # Blank-checked the way PrimitiveTypes normalizes names, so a
          # whitespace-only Type cannot synthesize a return here that
          # primitive discovery then treats as absent.
          params << build_return_parameter(op) unless PrimitiveTypes.normalize_name(op.type).empty?
          params
        end

        def build_owned_parameter(param)
          ::Xmi::Uml::OwnedParameter.new(
            id: @context.xmi_id_for(param),
            name: param.name,
            direction: normalize_direction(param.kind),
          )
        end

        def build_return_parameter(op)
          ::Xmi::Uml::OwnedParameter.new(
            id: @context.id_allocator.allocate(
              prefix: IdAllocator::RETURN_PARAMETER,
              seed: "return-#{op.operationid}",
              owner_id: @context.xmi_id_for(op),
            ),
            name: "return",
            direction: "return",
            type: type_reference(op.type, op.classifier),
          )
        end

        # ---- Shared helpers ---------------------------------------------

        def class_xmi_type(obj)
          obj.interface? ? "uml:Interface" : "uml:Class"
        end

        # EA's operation concurrency defaults to "Sequential" — omit
        # it so the xmi gem doesn't emit concurrency="sequential"
        # (EA's reference XMI omits the default).
        def normalize_concurrency(raw)
          return nil if raw.nil? || raw.to_s.strip.empty?

          value = raw.to_s.downcase
          value == "sequential" ? nil : value
        end

        # UML parameter direction defaults to "in" — omit it so the
        # xmi gem doesn't emit direction="in" (EA's reference XMI
        # omits the default).
        def normalize_direction(raw)
          return nil if raw.nil? || raw.to_s.strip.empty?

          value = raw.to_s.downcase
          value == "in" ? nil : value
        end

        def inheritance_connectors(obj, type)
          @context.connectors_for(obj.ea_object_id).select do |conn|
            conn.start_object_id == obj.ea_object_id && conn.connector_type == type
          end
        end

        # Realization connectors owned by this class — those where
        # this object is the source (client). Each emits an
        # `<interfaceRealization>`. Matched via the model predicate so
        # both EA spellings (Realization/Realisation) are recognized.
        def realization_connectors(obj)
          @context.connectors_for(obj.ea_object_id).select do |conn|
            conn.start_object_id == obj.ea_object_id && conn.realization?
          end
        end

        # EA walks classifiers in tree-position order (t_object.TPos,
        # ties broken by name then object id), not insertion order.
        # The global LI counter depends on it.
        def buildable_objects_in(pkg)
          @context.objects_in_package(pkg.package_id)
                  .reject { |o| note?(o) || package_object?(o) }
                  .sort_by { |o| [o.sort_position, o.name.to_s, o.ea_object_id] }
        end

        # Children nested under a classifier via t_object.ParentID.
        # Level-1 order in EA's reference is descending object id;
        # deeper levels don't match any column we've found — the LI
        # counters inside deep nests may drift until that's derived.
        def nested_classifiers_under(obj)
          @context.objects_in_package(obj.package_id)
                  .select { |o| o.parentid.to_i == obj.ea_object_id && adopted?(o) }
                  .sort_by { |o| [o.sort_position, -o.ea_object_id] }
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

        def primitive?(obj)
          obj.object_type == "PrimitiveType" ||
            (obj.gentype == "Java" && obj.stereotype_is?("primitive"))
        end

        # The fallback id comes from the same module that emits the
        # <primitivetypes> definitions, so the two normalize the name
        # identically. A name that is blank once stripped gets no
        # reference at all — PrimitiveTypes defines nothing for it.
        def type_reference(type_name, classifier)
          return nil if PrimitiveTypes.normalize_name(type_name).empty?

          classifier_ref(classifier) || PrimitiveTypes.definition_id(type_name)
        end

        # QEA stores t_attribute.Classifier / t_operation.Classifier as
        # an INTEGER t_object id ("0" = unresolved); EAP-era data can
        # carry a GUID instead. Resolve either to the object's xmi id.
        def classifier_ref(classifier)
          text = PrimitiveTypes.normalize_name(classifier)
          return nil if PrimitiveTypes.blank_classifier?(text)
          return GuidFormat.ea_guid_to_xmi_id(text) unless text.match?(/\A\d+\z/)

          obj = @context.object_by_id(text.to_i)
          obj && @context.xmi_id_for(obj)
        end

        def type_reference_model(type_name, classifier)
          if (href = PrimitiveTypes.href_for(type_name, classifier))
            return ::Xmi::Uml::Type.new(href: href)
          end

          ref = type_reference(type_name, classifier)
          ref ? ::Xmi::Uml::Type.new(idref: ref) : nil
        end

        def cardinality_for(conn, side)
          side == :source ? conn.sourcecard : conn.destcard
        end

        def role_name_for(conn, side)
          side == :source ? conn.sourcerole : conn.destrole
        end

        def containment_for(conn, side)
          side == :source ? conn.sourceisaggregate : conn.destisaggregate
        end

        # EA's t_connector does not expose per-end visibility (the
        # source/dest scopes are stored only on the role's target
        # object, which has its own visibility). Leave ownedEnd
        # visibility unset unless a future schema change exposes it.
        def visibility_for_end(_conn, _side)
          nil
        end

        # InstanceSpecification classifier reference. EA stores this
        # directly in t_object.classifier as the classifier's
        # ea_object_id (NOT pdata1, which is a separate column used
        # for other purposes on InstanceSpecification rows).
        def classifier_ref_for(obj)
          classifier_id = obj.classifier.to_i
          return nil if classifier_id.zero?

          classifier = @context.object_by_id(classifier_id)
          classifier ? @context.xmi_id_for(classifier) : nil
        end

        # InstanceSpecification slots, parsed from EA's RunState column.
        # Each `@VAR;Variable=<name>;Value=<v>;Op=<op>;@ENDVAR;` block
        # becomes one UML Slot with an OpaqueExpression value. The
        # `definingFeature` is resolved by looking up the named
        # attribute on the instance's classifier.
        def slots_for(obj)
          RunState.parse(obj.runstate).map do |binding|
            build_slot(obj, binding)
          end
        end

        def build_slot(instance, binding)
          ::Xmi::Uml::Slot.new(
            type: "uml:Slot",
            id: slot_id_for(instance, binding),
            defining_feature: defining_feature_for(instance, binding),
            value: [build_slot_value(instance, binding)],
          )
        end

        def build_slot_value(instance, binding)
          ::Xmi::Uml::OpaqueExpression.new(
            type: "uml:OpaqueExpression",
            id: opaque_expression_id_for(instance, binding),
            body_attribute: binding.body,
          )
        end

        def slot_id_for(instance, binding)
          @context.id_allocator.allocate(
            prefix: IdAllocator::SLOT,
            seed: "slot-#{instance.ea_object_id}-#{binding.variable}",
            owner_id: @context.xmi_id_for(instance),
          )
        end

        def opaque_expression_id_for(instance, binding)
          @context.id_allocator.allocate(
            prefix: IdAllocator::OPAQUE_EXPRESSION,
            seed: "oe-#{instance.ea_object_id}-#{binding.variable}",
            owner_id: @context.xmi_id_for(instance),
          )
        end

        # Resolve the definingFeature EAID for a RunState binding by
        # looking up the named attribute on the instance's classifier.
        # Returns nil when the classifier or attribute can't be found —
        # the slot still emits, just without the definingFeature ref.
        def defining_feature_for(instance, binding)
          classifier_id = instance.classifier.to_i
          return nil if classifier_id.zero?

          classifier = @context.object_by_id(classifier_id)
          return nil unless classifier

          attr = @context.attributes_for(classifier.ea_object_id)
            .find { |a| a.name == binding.variable }
          attr ? @context.xmi_id_for(attr) : nil
        end
      end
    end
  end
end
