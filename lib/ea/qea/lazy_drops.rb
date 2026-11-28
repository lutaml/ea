# frozen_string_literal: true

module Ea
  module Qea
    # Ea-native lazy rendering (#278): build the Liquid klass-table
    # drops' Lutaml::Uml objects per class, directly from the
    # Ea::Qea::Database rows — no XMI materialization. Presents the
    # LookupService-compatible contract the XMI-model-shaped drops
    # consume, answered from the database indexes instead of a Sparx
    # document graph.
    module LazyDrops
      autoload :QeaLookup, "ea/qea/lazy_drops/qea_lookup"

      # The parsed-source contract the plugin's klass-table cache
      # consumes: parser (model name + index), the lazy id index, and
      # the drop options.
      ParsedResult = Struct.new(:parser, :xmi_id_index, :drop_options,
                                keyword_init: true)

      class << self
        # Build a lazy drop context over a loaded database.
        #
        # @param database [Database] loaded QEA database
        # @param guidance [Object, nil] guidance document for the drops
        # @return [Context] the lazy per-class drop context
        def for(database, guidance: nil)
          require_uml!
          Context.new(database, guidance)
        end

        # Load a .qea file and return the parsed-source shape the
        # plugin's klass-table cache consumes — the .qea replacement
        # for the XMI parse pipeline, with no graph materialization.
        #
        # @param qea_path [String] path to the .qea file
        # @param guidance [Object, nil] guidance document
        # @return [ParsedResult]
        def parsed(qea_path, guidance: nil)
          require_uml!
          database = Services::DatabaseLoader.new(qea_path).load
          context = Context.new(database, guidance)
          ParsedResult.new(
            parser: context.parser,
            xmi_id_index: context.xmi_id_index,
            drop_options: context.drop_options
          )
        end

        # Load a .qea file into the Loaded graph shape the table
        # renders consume (parser, uml_document facade, drop options,
        # lazy id index) — the .qea branch of the XMI load_graph.
        #
        # @param qea_path [String] path to the .qea file
        # @param guidance [Object, nil] guidance document
        # @return [LazyGraph]
        def parsed_graph(qea_path, guidance: nil)
          require_uml!
          database = Services::DatabaseLoader.new(qea_path).load
          context = Context.new(database, guidance)
          LazyGraph.new(
            parser: context.parser,
            uml_document: LazyDocument.new(context),
            drop_options: context.drop_options,
            xmi_id_index: context.xmi_id_index
          )
        end

        private

        def require_uml!
          return if defined?(Lutaml::Uml::Document)

          require "lutaml/uml"
        rescue LoadError
          raise Ea::Error,
                "lutaml-uml is required for lazy drop construction."
        end
      end

      # Per-class lazy construction context. Classes are built on
      # first request and cached by their XMI id; packages are
      # wrappers over the database indexes, not materialized trees.
      class Context
        attr_reader :database, :guidance, :lookup

        def initialize(database, guidance = nil)
          @database = database
          @guidance = guidance
          @klass_cache = {}
          @lookup = QeaLookup.new(database)
          @class_transformer = Factory::ClassTransformer.new(database)
          @base = Factory::BaseTransformer.new(database)
        end

        # The drop-options contract shared by every drop: the QEA
        # lookup answers the cross-reference surface; there is no
        # xmi_root_model to walk (the drops tolerate its absence).
        def drop_options
          {
            lookup: lookup,
            with_gen: true,
            with_absolute_path: true
          }
        end

        # Build (or fetch the cached) UmlClass for one object row.
        #
        # @param ea_object_id [Integer] t_object.Object_ID
        # @return [Lutaml::Uml::UmlClass, nil] nil for non-class rows
        def klass_for(ea_object_id)
          object = database.find_object(ea_object_id)
          return nil unless object

          xmi_id = object_xmi_id(object)
          cache_hit = @klass_cache[xmi_id]
          return cache_hit if cache_hit

          klass = @class_transformer.transform(object)
          @klass_cache[xmi_id] = klass if klass
          klass
        end

        # All class-placed object ids on the database.
        #
        # @return [Array<Integer>] t_object ids whose rows are classes
        def class_object_ids
          database.objects.all.select(&:uml_class?).map(&:ea_object_id)
        end

        def object_xmi_id(object)
          @base.normalize_guid_to_xmi_format(object.ea_guid, "EAID")
        end

        # The lookup facade the drops consume (LookupService-compatible
        # surface over the database indexes).
        def method_missing(name, ...)
          lookup.respond_to?(name) ? lookup.public_send(name, ...) : super
        end

        def respond_to_missing?(name, include_private = false)
          lookup.respond_to?(name, include_private)
        end

        # The parse-level facade LookupService and the plugin's cache
        # bind to: the root-model stand-in, the packaged-element index,
        # and the whole cross-reference surface (QeaLookup).
        def parser
          @parser ||= ParserFacade.new(self)
        end

        # xmi_id -> Lutaml::Uml object, constructed on first access
        # per id (classes, enumerations, data types).
        def xmi_id_index
          @xmi_id_index ||= LazyIdIndex.new(self)
        end

        # The packaged-element index shim: name/type lookups and
        # parent walks over the database rows.
        def xmi_index
          @xmi_index ||= IndexShim.new(self)
        end

        # Enum-placed / datatype-placed object rows.
        def enum_object_ids
          database.objects.all.select(&:enumeration?).map(&:ea_object_id)
        end

        def data_type_object_ids
          database.objects.all.select(&:data_type?).map(&:ea_object_id)
        end

        def enum_for(ea_object_id)
          object = database.find_object(ea_object_id)
          object && Factory::EnumTransformer.new(database).transform(object)
        end

        def data_type_for(ea_object_id)
          object = database.find_object(ea_object_id)
          object && Factory::DataTypeTransformer.new(database).transform(object)
        end
      end

      # The Loaded graph shape the table renders consume. Classes are
      # constructed per package on demand and memoized on the
      # context's caches; the database stays the single source.
      class LazyGraph < Struct.new(:parser, :uml_document, :drop_options,
                                   :xmi_id_index, keyword_init: true)
      end

      # Document facade answering RootDrop's reads: name + packages.
      class LazyDocument
        def initialize(context)
          @context = context
        end

        def name
          "EA Model"
        end

        def packages
          @context.database.packages
                  .reject { |package| parent(package) }
                  .map { |package| LazyPackage.new(@context, package) }
        end

        private

        def parent(package)
          @context.database.find_package(package.parent_id)
        end
      end

      # Package facade over one t_package row: classes, enums, data
      # types and child packages construct on demand.
      class LazyPackage
        def initialize(context, package)
          @context = context
          @package = package
        end

        def name
          @package.name
        end

        def xmi_id
          @package.ea_guid ? ea_id(@package.ea_guid) : nil
        end

        def definition
          @package.notes ? Ea::Rtf.to_text(@package.notes.to_s) : nil
        end

        def stereotype
          nil
        end

        def classes
          @context.database.objects_in_package(@package.package_id)
                 .select(&:uml_class?)
                 .map { |row| @context.klass_for(row.ea_object_id) }
                 .compact
        end

        def enums
          @context.database.objects_in_package(@package.package_id)
                 .select(&:enumeration?)
                 .filter_map { |row| @context.enum_for(row.ea_object_id) }
        end

        def data_types
          @context.database.objects_in_package(@package.package_id)
                 .select(&:data_type?)
                 .filter_map { |row| @context.data_type_for(row.ea_object_id) }
        end

        def packages
          @context.database.child_packages_for(@package.package_id)
                 .map { |row| LazyPackage.new(@context, row) }
        end

        def diagrams
          []
        end

        private

        def ea_id(guid)
          Ea::GuidFormat.ea_guid_to_xmi_id(guid)
        end
      end

      # Stand-in for the xmi gem's root model: the klass-table cache
      # reads only its model name (to strip a leading path segment).
      class RootModelFacade
        Model = Struct.new(:name, keyword_init: true)

        def model
          Model.new(name: "EA Model")
        end
      end

      # Parse-level facade: binds LookupService and the plugin's
      # klass-table cache to the QEA lookups and the index shim.
      class ParserFacade
        def initialize(context)
          @context = context
        end

        def xmi_root_model
          RootModelFacade.new
        end

        def xmi_index
          @context.xmi_index
        end

        def doc_node_attribute_value(node_id, attr_name)
          @context.doc_node_attribute_value(node_id, attr_name)
        end

        def lookup_entity_name(xmi_id)
          @context.lookup_entity_name(xmi_id)
        end

        def lookup_attribute_documentation(xmi_id)
          @context.lookup_attribute_documentation(xmi_id)
        end

        def find_upper_level_packaged_element(klass_id)
          @context.find_upper_level_packaged_element(klass_id)
        end

        def find_matched_element(xmi_id)
          @context.find_matched_element(xmi_id)
        end

        def fetch_connector(link_id)
          @context.fetch_connector(link_id)
        end

        def fetch_definition_node_value(link_id, node_name)
          @context.fetch_definition_node_value(link_id, node_name)
        end

        def select_dependencies_by_supplier(supplier_id)
          @context.select_dependencies_by_supplier(supplier_id)
        end

        def select_dependencies_by_client(client_id)
          @context.select_dependencies_by_client(client_id)
        end

        def lookup_assoc_def(association)
          @context.lookup_assoc_def(association)
        end

        def lookup_connector_def_by_associationclass(association)
          @context.lookup_connector_def_by_associationclass(association)
        end
      end

      # Packaged-element index shim: name/type lookups and parent
      # walks over the database rows. Records are lightweight
      # stand-ins carrying id/name — construction happens through
      # the lazy id index.
      class IndexShim
        Record = Struct.new(:id, :name, :type, keyword_init: true)

        def initialize(context)
          @context = context
          @by_type = nil
          @parents = nil
        end

        def find_packaged_by_name_and_types(name, types)
          types.filter_map { |type| packaged_elements_of_type(type) }
               .flatten
               .find { |record| record.name == name }
        end

        def packaged_elements_of_type(type)
          by_type[type] || []
        end

        def find_parent(id)
          parents[id]
        end

        private

        def by_type
          @by_type ||= {
            "uml:Class" => records_for(@context.class_object_ids, "uml:Class"),
            "uml:AssociationClass" => [],
            "uml:Enumeration" => records_for(@context.enum_object_ids,
                                             "uml:Enumeration"),
            "uml:DataType" => records_for(@context.data_type_object_ids,
                                          "uml:DataType")
          }.freeze
        end

        def records_for(object_ids, type)
          object_ids.filter_map do |id|
            object = @context.database.find_object(id)
            next unless object&.name

            Record.new(id: @context.object_xmi_id(object), name: object.name,
                       type: type)
          end
        end

        def parents
          @parents ||= begin
            map = {}
            @context.database.objects.all.each do |object|
              next unless object.ea_guid

              id = Ea::GuidFormat.ea_guid_to_xmi_id(object.ea_guid)
              package = @context.database.find_package(object.package_id)
              next unless package&.ea_guid

              map[id] = Record.new(
                id: Ea::GuidFormat.ea_guid_to_xmi_id(package.ea_guid),
                name: package.name, type: "uml:Package"
              )
            end
            @context.database.packages.each do |package|
              next unless package.ea_guid

              id = Ea::GuidFormat.ea_guid_to_xmi_id(package.ea_guid)
              parent = @context.database.find_package(package.parent_id)
              next unless parent&.ea_guid

              map[id] = Record.new(
                id: Ea::GuidFormat.ea_guid_to_xmi_id(parent.ea_guid),
                name: parent.name, type: "uml:Package"
              )
            end
            map
          end
        end
      end

      # xmi_id -> Lutaml::Uml object, constructed on first access.
      # Dispatches on which database entity owns the id.
      class LazyIdIndex
        def initialize(context)
          @context = context
          @built = {}
        end

        def [](xmi_id)
          @built[xmi_id] ||= build(xmi_id)
        end

        private

        def build(xmi_id)
          context = @context
          database = context.database

          database.objects.all.each do |object|
            next unless object.ea_guid

            next unless Ea::GuidFormat.ea_guid_to_xmi_id(object.ea_guid) == xmi_id

            return case object
                   when ->(o) { o.uml_class? || o.interface? }
                     context.klass_for(object.ea_object_id)
                   when lambda(&:enumeration?)
                     context.enum_for(object.ea_object_id)
                   when lambda(&:data_type?)
                     context.data_type_for(object.ea_object_id)
                   end
          end
          nil
        end
      end
    end
  end
end
