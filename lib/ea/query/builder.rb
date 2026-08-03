# frozen_string_literal: true

module Ea
  module Query
    # Chainable query builder. Each method returns a new Builder
    # with the predicate applied — no mutation. Final #call returns
    # the filtered collection.
    #
    # Example:
    #   Ea::Query.new(model).classes.in_package("core")
    #            .with_stereotype("FeatureType").call
    class Builder
      attr_reader :model, :filters

      def initialize(model, filters: [], kind: :objects)
        @model = model
        @filters = filters
        @kind = kind
      end

      # Filter to UML classes only.
      # @return [Builder]
      def classes
        with_type("Class")
      end

      # Filter to interfaces only.
      # @return [Builder]
      def interfaces
        with_type("Interface")
      end

      # Filter to packages.
      # @return [Builder]
      def packages
        Builder.new(model, filters: filters, kind: :packages)
      end

      # Filter to diagrams.
      # @return [Builder]
      def diagrams
        Builder.new(model, filters: filters, kind: :diagrams)
      end

      # Filter by EA object_type (Class, Interface, Package, ...).
      # @return [Builder]
      def with_type(type)
        Builder.new(model, filters: filters + [->(o) { o.object_type == type }], kind: @kind)
      end

      # Restrict to elements in the named package.
      # @param name [String]
      # @return [Builder]
      def in_package(name)
        pkg = (model.collections[:packages] || []).find { |p| p.name == name }
        return self unless pkg

        filter_by { |o| o.package_id == pkg.package_id }
      end

      # Filter by applied stereotype name. Stereotype lookup walks
      # t_xref for @STEREO blocks referencing the object's ea_guid.
      # @param name [String]
      # @return [Builder]
      def with_stereotype(name)
        xrefs = model.collections[:xrefs] || []
        filter_by do |o|
          applied = stereotype_names_for(o, xrefs)
          applied.any? { |r| r == name }
        end
      end

      # Filter by name exact match.
      # @param name [String]
      # @return [Builder]
      def named(name)
        filter_by { |o| o.name == name }
      end

      # Filter by name substring (case-insensitive).
      # @param substring [String]
      # @return [Builder]
      def name_contains(substring)
        re = Regexp.new(Regexp.escape(substring), Regexp::IGNORECASE)
        filter_by { |o| o.name&.match?(re) }
      end

      # Add a custom filter proc.
      # @param block [Proc(Object)->Boolean]
      # @return [Builder]
      def filter_by(&block)
        Builder.new(model, filters: filters + [block], kind: @kind)
      end

      # Extract stereotype names applied to an object via t_xref.
      # Returns [] when no @STEREO block references the object's GUID.
      # @param object [Ea::Qea::Models::EaObject]
      # @param xrefs [Array<Ea::Qea::Models::EaXref>]
      # @return [Array<String>]
      def stereotype_names_for(object, xrefs)
        return [] unless object.is_a?(Ea::Qea::Models::EaObject)
        return [] unless object.ea_guid

        xrefs.select do |xr|
          xr.client == object.ea_guid && xr.description&.include?("@STEREO")
        end.map do |xr|
          xr.description.match(/Name=([^;]+)/)[1]
        end.compact
      end
      private :stereotype_names_for

      # Materialize the filtered collection.
      # @return [Array]
      def call
        records = model.collections[@kind] || []
        records.select { |o| filters.all? { |f| f.call(o) } }
      end

      # Enumerable support.
      include Enumerable

      def each(&block)
        call.each(&block)
      end
    end
  end
end
