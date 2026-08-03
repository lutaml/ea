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

      # Filter by applied stereotype name.
      # @param name [String]
      # @return [Builder]
      def with_stereotype(name)
        filter_by do |o|
          refs = o.respond_to?(:stereotype_refs) ? o.stereotype_refs : nil
          refs&.any? { |r| r == name }
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
