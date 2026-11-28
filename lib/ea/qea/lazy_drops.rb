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
      end
    end
  end
end
