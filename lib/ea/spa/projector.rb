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
      attr_reader :document, :shard_url_for, :configuration

      def initialize(document, shard_url_for: nil, configuration: nil)
        @document = document
        @shard_url_for = shard_url_for || default_shard_url
        @configuration = configuration
      end

      def skeleton
        Skeleton.new(
          metadata: metadata_hash,
          package_tree: build_package_tree,
          entries: build_entries,
          view_extras: view_extras
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
      # Diagrams are skipped when the configuration disables them.
      def each_shard
        return enum_for(:each_shard) unless block_given?

        document.classifiers.each { |c| yield shard_for(c) }
        document.packages.each { |p| yield shard_for(p) }
        document.diagrams.each { |d| yield shard_for(d) } if render_diagrams?
      end

      def render_diagrams?
        configuration ? configuration.render_diagrams? : true
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
        base = document.metadata
        merged = configuration ? configuration.apply_to_metadata(base) : base
        hash = JSON.parse(merged.to_json)
        hash["statistics"] = statistics_hash
        hash
      end

      def statistics_hash
        {
          "packages" => document.packages.size,
          "classes" => document.classifiers.size,
          "attributes" => document.classifiers.sum { |c| c.properties.size },
          "operations" => document.classifiers.sum { |c| c.operations.size },
          "associations" => document.relationships.count do |r|
            r.is_a?(Ea::Model::Association)
          end,
          "diagrams" => render_diagrams? ? document.diagrams.size : 0
        }
      end

      def view_extras
        configuration&.view_extras || {}
      end

      def build_package_tree
        sub_ids_by_parent = document.packages.group_by(&:parent_id)
        nodes = document.packages.map do |pkg|
          PackageTreeNode.new(
            id: pkg.id,
            name: pkg.name,
            parent_id: pkg.parent_id,
            child_ids: (pkg.sub_package_ids +
                        (sub_ids_by_parent[pkg.id] || []).map(&:id)).uniq,
            classifier_ids: classifiers_in_package_ids(pkg.id),
            diagram_ids: diagram_ids_for_package(pkg.id)
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
        classifier_entries = document.classifiers.map do |c|
          SkeletonEntry.new(
            id: c.id,
            name: c.name,
            kind: c.model_kind,
            package_id: c.package_id,
            qualified_name: c.qualified_name,
            shard_url: shard_url_for.call(c)
          )
        end
        package_entries = document.packages.map do |p|
          SkeletonEntry.new(
            id: p.id,
            name: p.name,
            kind: "package",
            package_id: p.parent_id,
            qualified_name: p.qualified_name,
            shard_url: shard_url_for.call(p)
          )
        end
        diagram_entries = render_diagrams? ? document.diagrams.map do |d|
          SkeletonEntry.new(
            id: d.id,
            name: d.name,
            kind: "diagram",
            package_id: d.package_id,
            qualified_name: d.name,
            shard_url: shard_url_for.call(d)
          )
        end : []
        classifier_entries + package_entries + diagram_entries
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

      def payload_for(model_element)
        payload = JSON.parse(model_element.to_json)
        case model_element
        when Ea::Model::Classifier
          augment_classifier_payload!(payload, model_element)
        when Ea::Model::Package
          payload["classifierIds"] = classifiers_in_package_ids(model_element.id)
          payload["diagramIds"] = diagram_ids_for_package(model_element.id)
        when Ea::Model::Diagram
          augment_diagram_payload!(payload, model_element)
        end
        payload
      end

      def diagram_ids_for_package(package_id)
        (document.packages.find { |p| p.id == package_id }&.diagram_ids ||
          []) + document.diagrams.select { |d| d.package_id == package_id }.map(&:id)
      end

      def augment_classifier_payload!(payload, classifier)
        rels = document.relationships_for(classifier.id)
        payload["generalizations"] = rels
          .select { |r| r.is_a?(Ea::Model::Generalization) && r.specific_id == classifier.id }
          .map { |r| { "id" => r.id, "targetId" => r.general_id } }
        payload["specializations"] = rels
          .select { |r| r.is_a?(Ea::Model::Generalization) && r.general_id == classifier.id }
          .map { |r| { "id" => r.id, "targetId" => r.specific_id } }
        payload["associations"] = rels
          .select { |r| r.is_a?(Ea::Model::Association) }
          .map { |r| association_stub(r, classifier.id) }
        payload
      end

      def association_stub(assoc, classifier_id)
        {
          "id" => assoc.id,
          "name" => assoc.name,
          "sourceId" => assoc.source_id,
          "targetId" => assoc.target_id,
          "thisEndRoleName" => assoc.source_id == classifier_id ? assoc.source_role_name : assoc.target_role_name,
          "otherEndRoleName" => assoc.source_id == classifier_id ? assoc.target_role_name : assoc.source_role_name,
          "otherEndId" => assoc.source_id == classifier_id ? assoc.target_id : assoc.source_id,
          "otherEndMultiplicity" => cardinality(assoc, classifier_id),
          "otherEndAggregation" => assoc.source_id == classifier_id ? assoc.target_aggregation : assoc.source_aggregation
        }
      end

      def cardinality(assoc, classifier_id)
        if assoc.source_id == classifier_id
          [assoc.target_multiplicity_lower, assoc.target_multiplicity_upper]
        else
          [assoc.source_multiplicity_lower, assoc.source_multiplicity_upper]
        end
      end

      def augment_diagram_payload!(payload, diagram)
        payload["svg"] = Ea::Svg::EaEmitter::Document.new(
          diagram,
          model_index: document.index_by_id,
          document: document
        ).render
        payload
      rescue StandardError => e
        warn "ea: skipping SVG render for diagram #{diagram.id} " \
             "(#{diagram.name.inspect}): #{e.class}: #{e.message}"
        payload
      end
    end
  end
end
