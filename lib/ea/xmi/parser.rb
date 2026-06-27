# frozen_string_literal: true

require "digest"
require "lutaml/path"

module Ea
  module Xmi
    # Parses EA XMI files into Lutaml::Uml::Document objects.
    #
    # Consolidates what was previously 6 separate modules
    # (Xml, XmiBase, XmiConnector, XmiClassMembers, XmiToUml,
    # XmiToUmlGeneralization) into a single coherent class.
    #
    # The XMI format handled here is EA/Sparx-specific.
    class Parser
      class << self
        # Parse an XMI file into a UML Document.
        def parse(xml)
          new.parse(get_xmi_model(xml))
        end

        # Parse XMI and serialize to Liquid drops for template rendering.
        def serialize_to_liquid(xml, guidance = nil)
          new.serialize_to_liquid(get_xmi_model(xml), guidance)
        end

        private

        def get_xmi_model(xml)
          ::Xmi::Sparx::Root.parse_xml(File.read(xml))
        end
      end

      # Public instance methods

      def parse(xmi_model)
        setup_model(xmi_model)
        build_document(xmi_model)
      end

      def serialize_to_liquid(xmi_model, guidance = nil)
        setup_model(xmi_model)
        document = build_document(xmi_model)
        lookup = LookupService.new(self)
        options = {
          xmi_root_model: @xmi_root_model,
          id_name_mapping: @id_name_mapping,
          lookup: lookup,
          with_gen: true,
          with_absolute_path: true,
        }
        LiquidDrops::RootDrop.new(document, guidance, options)
      end

      # Public read access for collaborators (LookupService)
      attr_reader :xmi_root_model

      def xmi_index
        if @xmi_index.nil? && @xmi_root_model
          @xmi_index = @xmi_root_model.index
          @id_name_mapping ||= @xmi_index.id_name_map
        end
        @xmi_index
      end

      def id_name_mapping
        @id_name_mapping
      end

      # Public lookup methods used by LookupService and Liquid drops

      def fetch_connector(link_id)
        xmi_index.find_connector(link_id)
      end

      def fetch_definition_node_value(link_id, node_name)
        connector_node = fetch_connector(link_id)
        return nil unless connector_node

        node = connector_node.public_send(node_name.to_sym)
        return nil unless node

        documentation = node.documentation
        if documentation.is_a?(::Xmi::Sparx::Element::Documentation)
          documentation&.value
        else
          documentation
        end
      end

      def get_package_name(package) # rubocop:disable Metrics/AbcSize
        return package.name unless package.name.nil?

        connector = fetch_connector(package.id)
        if connector.target&.model&.name
          return "#{connector.target.model.name} (#{package.type.split(':').last})"
        end

        "unnamed"
      end

      def find_packaged_element_by_id(id)
        xmi_index.find_packaged_element(id)
      end

      def find_upper_level_packaged_element(klass_id)
        xmi_index.find_parent(klass_id)
      end

      def find_subtype_of_from_owned_attribute_type(id) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        @pkg_elements_owned_attributes ||= begin
          cache = {}
          all_packaged_elements.each do |e|
            next unless e.owned_attribute

            e.owned_attribute.each do |oa|
              next unless oa.association && oa.uml_type && oa.uml_type.idref
              cache[oa.uml_type.idref] = e.name
            end
          end
          cache
        end

        @pkg_elements_owned_attributes[id]
      end

      def find_subtype_of_from_generalization(id) # rubocop:disable Metrics/AbcSize,Metrics:CyclomaticComplexity,Metrics:MethodLength,Metrics:PerceivedComplexity
        matched_element = xmi_index.find_element(id)
        return unless matched_element&.links&.any?

        matched_generalization = nil
        matched_element.links.each do |link|
          matched_generalization = link&.generalization&.find { |g| g.start == id }
          break if matched_generalization
        end

        return if matched_generalization&.end.nil?
        lookup_entity_name(matched_generalization.end)
      end

      def find_klass_packaged_element(path)
        lutaml_path = Lutaml::Path.parse(path)
        if lutaml_path.segments.one?
          return find_klass_packaged_element_by_name(path)
        end

        find_klass_packaged_element_by_path(lutaml_path)
      end

      def find_klass_packaged_element_by_name(name)
        xmi_index.find_packaged_by_name_and_types(name, ["uml:Class", "uml:AssociationClass"])
      end

      def find_enum_packaged_element_by_name(name)
        xmi_index.packaged_elements_of_type("uml:Enumeration").find { |e| e.name == name }
      end

      def select_dependencies_by_supplier(supplier_id)
        xmi_index.packaged_elements_of_type("uml:Dependency").select { |e| e.supplier == supplier_id }
      end

      def select_dependencies_by_client(client_id)
        xmi_index.packaged_elements_of_type("uml:Dependency").select { |e| e.client == client_id }
      end

      def find_packaged_element_by_name(name)
        xmi_index.packaged_elements.find { |e| e.name == name }
      end

      def doc_node_attribute_value(node_id, attr_name)
        doc_node = fetch_element(node_id)
        return unless doc_node

        doc_node.properties&.public_send(
          Lutaml::Model::Utils.snake_case(attr_name).to_sym
        )
      end

      def lookup_attribute_documentation(xmi_id)
        attribute_node = fetch_attribute_node(xmi_id)
        return unless attribute_node&.documentation

        attribute_node.documentation.value
      end

      def lookup_element_prop_documentation(xmi_id)
        element_node = xmi_index.find_element(xmi_id)
        return unless element_node&.properties

        element_node.properties.documentation
      end

      def lookup_entity_name(xmi_id)
        @id_name_mapping[xmi_id]
      end

      def lookup_assoc_def(association)
        connector = fetch_connector(association)
        connector&.documentation&.value
      end

      def get_ns_by_xmi_id(xmi_id)
        return unless xmi_id

        p = find_packaged_element_by_id(xmi_id)
        return unless p

        find_upper_level_packaged_element(p.id)&.name
      end

      def fetch_element(klass_id)
        xmi_index.find_element(klass_id)
      end

      def fetch_attribute_node(xmi_id)
        xmi_index.find_attribute(xmi_id)
      end

      def all_packaged_elements
        xmi_index.packaged_elements
      end

      def select_all_packaged_elements(all_elements, model, type)
        select_all_items(all_elements, model, type, :packaged_element)
        all_elements.delete_if { |e| !e.is_a?(::Xmi::Uml::PackagedElement) }
      end

      private

      # --- Model setup ---

      def setup_model(xmi_model)
        @xmi_root_model ||= xmi_model
        if @xmi_index.nil?
          @xmi_index = @xmi_root_model.index
          @id_name_mapping = @xmi_index.id_name_map
        end
      end

      # --- Document building ---

      def build_document(xmi_model)
        ::Lutaml::Uml::Document.new.tap do |doc|
          doc.name = xmi_model.model.name
          doc.packages = build_packages(xmi_model.model)
        end
      end

      def build_packages(model)
        return [] if model.packaged_element.nil?

        packages = model.packaged_element.select { |e| e.type?("uml:Package") }
        packages.map { |package| build_package(package) }
      end

      def build_package(package)
        ::Lutaml::Uml::Package.new.tap do |pkg|
          pkg.xmi_id = package.id
          pkg.name = get_package_name(package)
          pkg.definition = doc_node_attribute_value(package.id, "documentation")
          st = doc_node_attribute_value(package.id, "stereotype")
          pkg.stereotype = [st] if st

          pkg.packages = build_packages(package)
          pkg.classes = build_classes(package)
          pkg.enums = build_enums(package)
          pkg.data_types = build_data_types(package)
          pkg.diagrams = build_diagrams(package.id)
        end
      end

      def build_classes(package)
        return [] if package.packaged_element.nil?

        klasses = package.packaged_element.select do |e|
          e.type?("uml:Class") || e.type?("uml:AssociationClass") ||
            e.type?("uml:Interface")
        end

        klasses.map { |klass| build_class(klass) }
      end

      def build_class(klass) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics:CyclomaticComplexity,Metrics:PerceivedComplexity
        ::Lutaml::Uml::UmlClass.new.tap do |k|
          k.xmi_id = klass.id
          k.name = klass.name
          k.type = klass.type.split(":").last
          k.is_abstract = doc_node_attribute_value(klass.id, "isAbstract")
          k.definition = doc_node_attribute_value(klass.id, "documentation")
          k_st = doc_node_attribute_value(klass.id, "stereotype")
          k.stereotype = [k_st] if k_st

          k.attributes = build_class_attributes(klass)
          k.associations = build_associations(klass.id)
          k.operations = build_operations(klass)
          k.constraints = build_constraints(klass.id)
          k.association_generalization = build_assoc_generalizations(klass)

          if klass.type?("uml:Class")
            k.generalization = build_generalization(klass)
          end
        end
      end

      def build_enums(package) # rubocop:disable Metrics:MethodLength,Metrics:AbcSize
        return [] if package.packaged_element.nil?

        package.packaged_element
          .select { |e| e.type?("uml:Enumeration") }
          .map do |enum|
            ::Lutaml::Uml::Enum.new.tap do |en|
              en.xmi_id = enum.id
              en.name = enum.name
              en.values = build_values(enum)
              en.definition = doc_node_attribute_value(enum.id, "documentation")
              en_st = doc_node_attribute_value(enum.id, "stereotype")
              en.stereotype = [en_st] if en_st
            end
          end
      end

      def build_data_types(package) # rubocop:disable Metrics:AbcSize,Metrics:MethodLength
        return [] if package.packaged_element.nil?

        package.packaged_element
          .select { |e| e.type?("uml:DataType") }
          .map do |dt|
            ::Lutaml::Uml::DataType.new.tap do |data_type|
              data_type.xmi_id = dt.id
              data_type.name = dt.name
              data_type.is_abstract = doc_node_attribute_value(dt.id, "isAbstract")
              data_type.definition = doc_node_attribute_value(dt.id, "documentation")
              dt_st = doc_node_attribute_value(dt.id, "stereotype")
              data_type.stereotype = [dt_st] if dt_st

              data_type.attributes = build_class_attributes(dt)
              data_type.operations = build_operations(dt)
              data_type.associations = build_associations(dt.id)
              data_type.constraints = build_constraints(dt.id)
            end
          end
      end

      def build_diagrams(node_id) # rubocop:disable Metrics:AbcSize,Metrics:MethodLength
        return [] if @xmi_root_model.extension&.diagrams&.diagram.nil?

        diagram_lookup[node_id].map do |diagram|
          ::Lutaml::Uml::Diagram.new.tap do |dia|
            dia.xmi_id = diagram.id
            dia.name = diagram&.properties&.name
            dia.definition = diagram&.properties&.documentation

            package_id = diagram&.model&.package
            if package_id
              dia.package_id = package_id
              dia.package_name = find_packaged_element_by_id(package_id)&.name
            end
          end
        end
      end

      def build_class_attributes(klass) # rubocop:disable Metrics:AbcSize,Metrics:CyclomaticComplexity,Metrics:MethodLength
        return [] if klass.owned_attribute.nil?

        all_props = klass.owned_attribute.select { |attr| attr.type?("uml:Property") }
        all_props.filter_map { |oa| build_attribute(oa) }
      end

      def build_attribute(owned_attr) # rubocop:disable Metrics:AbcSize,Metrics:MethodLength
        uml_type = owned_attr.uml_type
        uml_type_idref = uml_type.idref if uml_type

        ::Lutaml::Uml::TopElementAttribute.new.tap do |attr|
          attr.id = owned_attr.id
          attr.name = owned_attr.name
          attr.type = lookup_entity_name(uml_type_idref) || uml_type_idref
          attr.xmi_id = uml_type_idref
          attr.is_derived = !!owned_attr.is_derived
          attr.cardinality = ::Lutaml::Uml::Cardinality.new.tap do |car|
            car.min = owned_attr.lower_value&.value
            car.max = owned_attr.upper_value&.value
          end
          attr.definition = lookup_attribute_documentation(owned_attr.id)

          if owned_attr.association
            attr.association = owned_attr.association
            attr.definition = lookup_assoc_def(owned_attr.association)
            attr.type_ns = get_ns_by_xmi_id(attr.xmi_id)
          end
        end
      end

      def build_associations(xmi_id) # rubocop:disable Metrics:AbcSize,Metrics:CyclomaticComplexity,Metrics:MethodLength,Metrics:PerceivedComplexity
        matched_element = xmi_index&.find_element(xmi_id)
        return if !matched_element || !matched_element.links

        links = []
        matched_element.links.each do |link|
          links << link.association if link.association.any?
        end

        links.flatten.compact.filter_map do |assoc|
          build_association(assoc, xmi_id)
        end
      end

      def build_association(assoc, xmi_id) # rubocop:disable Metrics:AbcSize,Metrics:CyclomaticComplexity,Metrics:MethodLength
        link_member = assoc.start == xmi_id ? "end" : "start"
        link_owner = link_member == "start" ? "end" : "start"

        member_end, member_end_type, member_end_cardinality,
          member_end_attribute_name, member_end_xmi_id =
          serialize_member_type(xmi_id, assoc, link_member)

        owner_end = serialize_owned_type(xmi_id, assoc, link_owner)
        doc_node = link_member == "start" ? "source" : "target"
        definition = fetch_definition_node_value(assoc.id, doc_node)

        owner_end_attribute_name = find_owner_attribute_name(xmi_id, assoc.id)

        return nil unless member_end &&
          ((member_end_type != "aggregation") ||
           (member_end_type == "aggregation" && member_end_attribute_name))

        ::Lutaml::Uml::Association.new.tap do |association|
          association.xmi_id = assoc.id
          association.member_end = member_end
          association.member_end_type = member_end_type
          association.member_end_cardinality = build_cardinality(member_end_cardinality)
          association.member_end_attribute_name = member_end_attribute_name
          association.member_end_xmi_id = member_end_xmi_id
          association.owner_end = owner_end
          association.owner_end_xmi_id = xmi_id
          association.owner_end_attribute_name = owner_end_attribute_name
          association.definition = definition
        end
      end

      def build_cardinality(hash)
        return nil unless hash

        ::Lutaml::Uml::Cardinality.new.tap do |cardinality|
          cardinality.min = hash[:min]
          cardinality.max = hash[:max]
        end
      end

      def build_operations(klass) # rubocop:disable Metrics:MethodLength,Metrics:AbcSize
        return [] if klass.owned_operation.nil?

        klass.owned_operation.filter_map do |operation|
          uml_type = operation.uml_type.first
          uml_type_idref = uml_type.idref if uml_type

          if !operation.class.attributes.key?(:association) || operation.association.nil?
            ::Lutaml::Uml::Operation.new.tap do |op|
              op.id = operation.id
              op.xmi_id = uml_type_idref
              op.name = operation.name
              op.definition = lookup_attribute_documentation(operation.id)
            end
          end
        end
      end

      def build_constraints(klass_id) # rubocop:disable Metrics:MethodLength,Metrics:AbcSize
        connector_node = fetch_connector(klass_id)
        return [] if connector_node.nil?

        constraints = %i[source target].map do |st|
          connector_node.public_send(st).constraints.constraint
        end.flatten

        constraints.map do |constraint|
          ::Lutaml::Uml::Constraint.new.tap do |con|
            con.name = CGI.unescapeHTML(constraint.name)
            con.type = constraint.type
            con.weight = constraint.weight
            con.status = constraint.status
          end
        end
      end

      def build_values(enum) # rubocop:disable Metrics:MethodLength,Metrics:CyclomaticComplexity,Metrics:AbcSize
        return [] if enum.owned_literal.nil?

        enum.owned_literal
          .select { |lit| lit.type?("uml:EnumerationLiteral") }
          .map do |owned_literal|
            uml_type_id = owned_literal&.uml_type&.idref

            ::Lutaml::Uml::Value.new.tap do |value|
              value.name = owned_literal.name
              value.type = lookup_entity_name(uml_type_id) || uml_type_id
              value.definition = lookup_attribute_documentation(owned_literal.id)
            end
          end
      end

      # --- Generalization building ---

      def build_generalization(klass) # rubocop:disable Metrics:AbcSize,Metrics:MethodLength,Metrics:CyclomaticComplexity,Metrics:PerceivedComplexity
        uml_general_obj, next_general_node_id = get_uml_general(klass.id)
        return uml_general_obj unless next_general_node_id

        if uml_general_obj.general
          inherited_props = []
          inherited_assoc_props = []
          level = 0

          loop_general_item(
            uml_general_obj.general, level, inherited_props, inherited_assoc_props
          )
          uml_general_obj.inherited_props = inherited_props.reverse
          uml_general_obj.inherited_assoc_props = inherited_assoc_props.reverse
        end

        uml_general_obj
      end

      def build_generalization_attributes(uml_general_obj) # rubocop:disable Metrics:AbcSize,Metrics:MethodLength
        upper_klass = uml_general_obj.general_upper_klass
        gen_attrs = uml_general_obj.general_attributes
        gen_name = uml_general_obj.general_name

        gen_attrs&.each do |i|
          name_ns = case i.type_ns
                    when "core", "gml"
                      upper_klass
                    else
                      i.type_ns
                    end
          name_ns = upper_klass if name_ns.nil?

          i.name_ns = name_ns
          i.gen_name = gen_name
          i.name = "" if i.name.nil?
        end

        gen_attrs
      end

      def get_uml_general(general_id) # rubocop:disable Metrics:AbcSize,Metrics:MethodLength
        general_node = find_packaged_element_by_id(general_id)
        return [] unless general_node

        general_node_attrs = get_uml_general_attributes(general_node)
        general_upper_klass = find_upper_level_packaged_element(general_id)
        next_general_node_id = general_node.generalization.first&.general

        uml_general = build_uml_general_node(
          general_id, general_node, general_node_attrs,
          general_upper_klass, next_general_node_id
        )

        assign_general_properties(uml_general)

        [uml_general, next_general_node_id]
      end

      def build_uml_general_node(general_id, general_node, attrs, upper_klass, next_id)
        gen = ::Lutaml::Uml::Generalization.new
        assign_general_basic_props(gen, general_id, general_node, attrs, upper_klass)
        assign_stereotype(gen, general_id)
        assign_parent_generalization(gen, general_node, next_id)
        gen
      end

      def assign_general_basic_props(gen, general_id, general_node, attrs, upper_klass)
        gen.general_id = general_id
        gen.general_name = general_node.name
        gen.general_attributes = attrs
        gen.general_upper_klass = upper_klass ? get_package_name(upper_klass) : nil
        gen.name = general_node.name
        gen.type = general_node.type
        gen.definition = lookup_element_prop_documentation(general_id)
      end

      def assign_stereotype(gen, general_id)
        gen_st = doc_node_attribute_value(general_id, "stereotype")
        gen.stereotype = [gen_st] if gen_st
      end

      def assign_parent_generalization(gen, general_node, next_id)
        return unless next_id

        gen.general = set_uml_generalization(next_id)
        gen.has_general = true
        gen.general_id = general_node.id
        gen.general_name = general_node.name
      end

      def assign_general_properties(uml_general)
        uml_general.attributes = build_generalization_attributes(uml_general)
        uml_general.owned_props = uml_general.attributes.select { |a| a.association.nil? }
        uml_general.assoc_props = uml_general.attributes.select(&:association)
      end

      def get_uml_general_attributes(general_node) # rubocop:disable Metrics:AbcSize,Metrics:MethodLength
        attrs = build_class_attributes(general_node)

        attrs.map do |attr|
          ::Lutaml::Uml::GeneralAttribute.new.tap do |gen_attr|
            gen_attr.id = attr.id
            gen_attr.name = attr.name
            gen_attr.type = attr.type
            gen_attr.xmi_id = attr.xmi_id
            gen_attr.is_derived = !!attr.is_derived
            gen_attr.cardinality = attr.cardinality
            gen_attr.definition = attr.definition&.strip
            gen_attr.association = attr.association
            gen_attr.has_association = !!attr.association
            gen_attr.type_ns = attr.type_ns
          end
        end
      end

      def set_uml_generalization(general_id)
        uml_general_obj, next_general_node_id = get_uml_general(general_id)

        if next_general_node_id
          uml_general_obj.general = set_uml_generalization(next_general_node_id)
          uml_general_obj.has_general = true
        end

        uml_general_obj
      end

      def loop_general_item( # rubocop:disable Metrics:MethodLength,Metrics:AbcSize,Metrics:PerceivedComplexity,Metrics:CyclomaticComplexity
        general_item, level, inherited_props, inherited_assoc_props
      )
        gen_upper_klass = general_item.general_upper_klass
        gen_name = general_item.general_name

        general_item.attributes.reverse_each do |attr|
          attr.upper_klass = gen_upper_klass
          attr.gen_name = gen_name
          attr.level = level

          if attr.association
            inherited_assoc_props << attr
          else
            inherited_props << attr
          end
        end

        if general_item&.has_general && general_item.general
          level += 1
          loop_general_item(
            general_item.general, level, inherited_props, inherited_assoc_props
          )
        end
      end

      def build_assoc_generalizations(klass) # rubocop:disable Metrics:AbcSize
        return [] if klass.generalization.nil? || klass.generalization.empty?

        klass.generalization.map do |gen|
          ::Lutaml::Uml::AssociationGeneralization.new.tap do |assoc_gen|
            assoc_gen.id = gen.id
            assoc_gen.type = gen.type
            assoc_gen.general = gen.general
          end
        end
      end

      # --- Connector serialization ---

      def serialize_owned_type(owner_xmi_id, link, link_owner_name)
        case link
        when ::Xmi::Sparx::Element::NoteLink
          return
        when ::Xmi::Sparx::Element::Generalization
          owner_end, = generalization_association(owner_xmi_id, link)
          return owner_end
        end

        xmi_id = link.public_send(link_owner_name.to_sym)
        lookup_entity_name(xmi_id) || connector_source_name(xmi_id)
      end

      def serialize_member_end(owner_xmi_id, link) # rubocop:disable Metrics:MethodLength,Metrics:AbcSize,Metrics:CyclomaticComplexity
        case link.name
        when "NoteLink"
          return
        when "Generalization"
          return generalization_association(owner_xmi_id, link)
        end

        xmi_id = link.start
        source_or_target = :source

        if link.start == owner_xmi_id
          xmi_id = link.end
          source_or_target = :target
        end

        connector = fetch_connector(link.id)
        ea_type = connector&.properties&.ea_type
        member_end_type = ea_type&.downcase

        member_end = member_end_name(xmi_id, source_or_target, link)
        [member_end, member_end_type, xmi_id]
      end

      def member_end_name(xmi_id, source_or_target, link) # rubocop:disable Metrics:MethodLength
        connector_label = connector_labels(xmi_id, source_or_target)
        entity_name = lookup_entity_name(xmi_id)
        connector_name = connector_name_by_source_or_target(xmi_id, source_or_target)

        case link
        when ::Xmi::Sparx::Element::Aggregation
          connector_label || entity_name || connector_name
        else
          entity_name || connector_name
        end
      end

      def serialize_member_type(owner_xmi_id, link, link_member_name) # rubocop:disable Metrics:MethodLength,Metrics:AbcSize
        member_end, member_end_type, xmi_id =
          serialize_member_end(owner_xmi_id, link)

        if link.is_a?(::Xmi::Sparx::Element::Association)
          connector_type = link_member_name == "start" ? "source" : "target"
          member_end_cardinality, member_end_attribute_name =
            fetch_assoc_connector(link.id, connector_type)
        else
          member_end_cardinality, member_end_attribute_name =
            fetch_owned_attribute_node(xmi_id)
        end

        if fetch_connector_name(link.id)
          member_end = fetch_connector_name(link.id)
        end

        [member_end, member_end_type, member_end_cardinality,
         member_end_attribute_name, xmi_id]
      end

      def fetch_connector_name(link_id)
        connector = fetch_connector(link_id)
        connector&.name
      end

      def fetch_assoc_connector(link_id, connector_type)
        connector = fetch_connector(link_id)
        return [nil, nil] unless connector

        assoc_connector = connector.public_send(connector_type.to_sym)
        return [nil, nil] unless assoc_connector

        [extract_cardinality(assoc_connector), extract_attribute_name(assoc_connector)]
      end

      def extract_cardinality(assoc_connector)
        assoc_connector_type = assoc_connector.type
        min = nil
        max = nil
        if assoc_connector_type&.multiplicity
          cardinality = assoc_connector_type.multiplicity.split("..")
          cardinality.unshift("1") if cardinality.length == 1
          min, max = cardinality
        end
        cardinality_min_max_value(min, max)
      end

      def extract_attribute_name(assoc_connector)
        assoc_connector.role ? assoc_connector.model.name : nil
      end

      def generalization_association(owner_xmi_id, link) # rubocop:disable Metrics:MethodLength
        member_end_type = "generalization"
        xmi_id = link.start
        source_or_target = :source

        if link.start == owner_xmi_id
          member_end_type = "inheritance"
          xmi_id = link.end
          source_or_target = :target
        end

        member_end = member_end_name(xmi_id, source_or_target, link)
        [member_end, member_end_type, xmi_id]
      end

      def fetch_owned_attribute_node(xmi_id)
        oa = xmi_index.find_owned_attrs_by_type(xmi_id)
          .find { |a| !!a.association }

        if oa
          cardinality = cardinality_min_max_value(
            oa.lower_value&.value, oa.upper_value&.value
          )
          oa_name = oa.name
        end

        [cardinality, oa_name]
      end

      def find_owner_attribute_name(owner_xmi_id, assoc_id)
        owner_node = find_packaged_element_by_id(owner_xmi_id)
        return nil unless owner_node&.owned_attribute

        owned_attr = owner_node.owned_attribute.find { |oa| oa.association == assoc_id }
        owned_attr&.name
      end

      # --- Connector lookup index ---

      def diagram_lookup
        @diagram_lookup ||= begin
          idx = Hash.new { |h, k| h[k] = [] }
          xmi_diagrams.each { |d| idx[d.model.package] << d if d.model&.package }
          idx
        end
      end

      def xmi_diagrams
        @xmi_root_model.extension&.diagrams&.diagram || []
      end

      def connector_lookup
        @connector_lookup ||= begin
          lookup = {}
          connectors = @xmi_root_model.extension&.connectors&.connector || []
          connectors.each { |con| index_connector_directions(con, lookup) }
          lookup
        end
      end

      def index_connector_directions(con, lookup)
        %i[source target].each do |dir|
          idref = con.public_send(dir)&.idref
          lookup[[dir, idref]] = con if idref
        end
      end

      def connector_node_by_id(xmi_id, source_or_target)
        connector_lookup[[source_or_target.to_sym, xmi_id]]
      end

      def connector_name_by_source_or_target(xmi_id, source_or_target) # rubocop:disable Metrics:AbcSize
        node = connector_node_by_id(xmi_id, source_or_target)
        return node.name if node&.name

        return if node.nil? ||
          node.public_send(source_or_target.to_sym).nil? ||
          node.public_send(source_or_target.to_sym).model.nil?

        node.public_send(source_or_target.to_sym).model.name
      end

      def connector_labels(xmi_id, source_or_target)
        node = connector_node_by_id(xmi_id, source_or_target)
        return if node.nil?

        node.labels&.rt || node.labels&.lt
      end

      def connector_source_name(xmi_id)
        connector_name_by_source_or_target(xmi_id, :source)
      end

      def cardinality_min_max_value(min, max)
        { min: min, max: max }
      end

      def select_all_items(items, model, type, method)
        iterate_tree(items, model, type, method.to_sym)
      end

      def iterate_tree(result, node, type, children_method) # rubocop:disable Metrics:AbcSize,Metrics:CyclomaticComplexity,Metrics:PerceivedComplexity
        result << node if type.nil? || node.type == type
        return unless node.public_send(children_method)

        node.public_send(children_method).each do |sub_node|
          if sub_node.public_send(children_method)
            iterate_tree(result, sub_node, type, children_method)
          elsif type.nil? || sub_node.type == type
            result << sub_node
          end
        end
      end

      def find_klass_packaged_element_by_path(path)
        if path.absolute?
          iterate_packaged_element(@xmi_root_model.model, path.segments.map(&:name))
        else
          iterate_relative_packaged_element(path.segments.map(&:name))
        end
      end

      def iterate_relative_packaged_element(name_array)
        matched_elements = xmi_index.packaged_elements_of_type("uml:Package")
          .select { |e| e.name == name_array[0] }

        result = matched_elements.map do |e|
          iterate_packaged_element(e, name_array, type: "uml:Class")
        end

        result.compact.first
      end

      def iterate_packaged_element(model, name_array, index: 1, type: "uml:Package")
        return model if index == name_array.count

        model = model.packaged_element.find do |p|
          p.name == name_array[index] && p.type?(type)
        end

        return nil if model.nil?

        index += 1
        type = index == name_array.count - 1 ? "uml:Class" : "uml:Package"
        iterate_packaged_element(model, name_array, index: index, type: type)
      end
    end
  end
end
