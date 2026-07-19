# frozen_string_literal: true

module Ea
  module Spa
    # One-way transform: Ea::Model::Document → SPA view artifacts.
    #
    # The projector walks the model once and emits:
    # - Skeleton (with package tree + per-classifier entries)
    # - SearchIndex (flat searchable rows)
    # - Shards (one per entity, generated lazily via #shard_for)
    #
    # Sharding strategy is configurable via the `shard_url_for`
    # proc — by default it produces "data/<kind>s/<id>.json" paths
    # matching the sharded output strategy.
    class Projector
      attr_reader :document, :shard_url_for

      def initialize(document, shard_url_for: nil)
        @document = document
        @shard_url_for = shard_url_for || default_shard_url
      end

      def skeleton
        Skeleton.new(
          metadata: metadata_hash,
          package_tree: build_package_tree,
          entries: build_entries
        )
      end

      def search_index
        SearchIndex.new(entries: build_search_entries)
      end

      def shard_for(model_element)
        Shard.new(
          id: model_element.id,
          kind: kind_of(model_element),
          payload: payload_for(model_element)
        )
      end

      # Enumerate every (id, kind, shard) triple the SPA can address.
      def each_shard
        return enum_for(:each_shard) unless block_given?

        document.classifiers.each { |c| yield shard_for(c) }
        document.packages.each { |p| yield shard_for(p) }
        document.diagrams.each { |d| yield shard_for(d) }
      end

      private

      def default_shard_url
        lambda do |element|
          kind = kind_of(element)
          "data/#{pluralize(kind)}/#{element.id}.json"
        end
      end

      def pluralize(kind)
        case kind
        when "class" then "classes"
        when "property" then "properties"
        else "#{kind}s"
        end
      end

      def metadata_hash
        JSON.parse(document.metadata.to_json)
      end

      def build_package_tree
        nodes = document.packages.map do |pkg|
          PackageTreeNode.new(
            id: pkg.id,
            name: pkg.name,
            parent_id: pkg.parent_id,
            child_ids: pkg.sub_package_ids,
            classifier_ids: classifiers_in_package_ids(pkg.id),
            diagram_ids: pkg.diagram_ids
          )
        end
        PackageTree.new(
          root_ids: document.root_packages.map(&:id),
          nodes: nodes
        )
      end

      def classifiers_in_package_ids(package_id)
        document.classifiers_in_package(package_id).map(&:id)
      end

      def build_entries
        document.classifiers.map do |c|
          SkeletonEntry.new(
            id: c.id,
            name: c.name,
            kind: c.model_kind,
            package_id: c.package_id,
            qualified_name: c.qualified_name,
            shard_url: shard_url_for.call(c)
          )
        end
      end

      def build_search_entries
        entries = []
        document.classifiers.each do |c|
          entries << search_entry_for_classifier(c)
          c.properties.each { |p| entries << search_entry_for_property(p, c) }
        end
        document.packages.each { |p| entries << search_entry_for_package(p) }
        entries
      end

      def search_entry_for_classifier(c)
        SearchEntry.new(
          id: c.id,
          kind: c.model_kind,
          name: c.name,
          qualified_name: c.qualified_name,
          package: package_qualified_name(c.package_id),
          content: classifier_search_content(c),
          boost: 1.5
        )
      end

      def search_entry_for_property(prop, owner)
        SearchEntry.new(
          id: prop.id,
          kind: "property",
          name: prop.name,
          qualified_name: "#{owner.qualified_name}::#{prop.name}",
          package: package_qualified_name(owner.package_id),
          content: [prop.name, prop.type_name, prop.annotations.map(&:body)].flatten.compact.join(" "),
          boost: 1.0
        )
      end

      def search_entry_for_package(pkg)
        SearchEntry.new(
          id: pkg.id,
          kind: "package",
          name: pkg.name,
          qualified_name: pkg.qualified_name,
          package: pkg.parent_id ? package_qualified_name(pkg.parent_id) : "",
          content: [pkg.name, pkg.annotations.map(&:body)].flatten.compact.join(" "),
          boost: 1.2
        )
      end

      def classifier_search_content(c)
        parts = [c.name, c.qualified_name, c.stereotype_refs].compact
        parts << c.properties.map(&:name)
        parts << c.operations.map(&:name)
        parts << c.annotations.map(&:body)
        parts.flatten.compact.join(" ").gsub(/\s+/, " ").strip
      end

      def package_qualified_name(package_id)
        return "" if package_id.nil?

        pkg = document.index_by_id[package_id]
        pkg&.qualified_name || ""
      end

      def kind_of(element)
        case element
        when Ea::Model::Klass then "class"
        when Ea::Model::Enumeration then "enumeration"
        when Ea::Model::DataType then "data_type"
        when Ea::Model::PrimitiveType then "primitive_type"
        when Ea::Model::Interface then "interface"
        when Ea::Model::Package then "package"
        when Ea::Model::Diagram then "diagram"
        else "element"
        end
      end

      def payload_for(element)
        JSON.parse(element.to_json)
      end
    end
  end
end
