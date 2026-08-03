# frozen_string_literal: true

module Ea
  module Model
    # Discriminator → subclass maps for polymorphic Classifier and
    # Relationship collections. Defined here (rather than autoloaded)
    # because lutaml-model needs them at class-evaluation time, and
    # autoload only triggers on first constant reference.
    CLASSIFIER_POLYMORPHIC_MAP = {
      attribute: "modelKind",
      class_map: {
        "class" => "Ea::Model::Klass",
        "data_type" => "Ea::Model::DataType",
        "primitive_type" => "Ea::Model::PrimitiveType",
        "enumeration" => "Ea::Model::Enumeration",
        "interface" => "Ea::Model::Interface",
        "signal" => "Ea::Model::Signal"
      }
    }.freeze

    RELATIONSHIP_POLYMORPHIC_MAP = {
      attribute: "relationshipKind",
      class_map: {
        "association" => "Ea::Model::Association",
        "generalization" => "Ea::Model::Generalization",
        "realization" => "Ea::Model::Realization",
        "dependency" => "Ea::Model::Dependency"
      }
    }.freeze

    # Root container for a harmonized model. Source adapters build
    # one of these; consumer adapters read from it.
    #
    # Element identity is global within the document: every package,
    # classifier, relationship, diagram, and diagram element has a
    # unique `id`. References between elements are by id, so the
    # document can be sharded cheaply (no need to walk a tree to
    # resolve a reference).
    class Document < Base
      attribute :metadata, Metadata
      attribute :packages, Package, collection: true, initialize_empty: true
      attribute :classifiers, Classifier, collection: true, initialize_empty: true,
                                          polymorphic: CLASSIFIER_POLYMORPHIC_MAP
      attribute :relationships, Relationship, collection: true, initialize_empty: true,
                                              polymorphic: RELATIONSHIP_POLYMORPHIC_MAP
      attribute :stereotypes, Stereotype, collection: true, initialize_empty: true
      attribute :notes, Note, collection: true, initialize_empty: true
      attribute :instance_specifications, InstanceSpecification, collection: true,
                                          initialize_empty: true
      attribute :diagrams, Diagram, collection: true, initialize_empty: true

      # Flat lookup indexes, built lazily by consumers. Not
      # serialized — they're derived from the element collections.
      #
      # EA XMI stores packages with `EAPK_<guid>` ids inside the
      # uml:Model hierarchy, but diagram element `subject=` refs use
      # `EAID_<guid>`. We alias packages under both prefixes so
      # `model_element_ref` lookups from diagram elements resolve.
      def index_by_id
        @index_by_id ||= begin
          idx = {}
          packages.each do |p|
            idx[p.id] = p
            alias_eaid_for_package(idx, p)
          end
          classifiers.each { |c| idx[c.id] = c }
          relationships.each { |r| idx[r.id] = r }
          stereotypes.each { |s| idx[s.id] = s }
          instance_specifications.each { |i| idx[i.id] = i }
          diagrams.each { |d| idx[d.id] = d }
          notes.each { |n| idx[n.id] = n }
          diagrams.each do |d|
            d.elements.each { |e| idx[e.id] = e }
            d.connectors.each { |c| idx[c.id] = c }
          end
          idx
        end
      end

      # Flat lookup of Properties by id across all classifiers. Built
      # lazily; not serialized. Used by connector label rendering to
      # resolve association-end properties in O(1) rather than
      # walking every classifier's property list per lookup.
      def property_index
        @property_index ||= begin
          idx = {}
          classifiers.each do |cls|
            (cls.properties || []).each { |p| idx[p.id] = p }
          end
          idx
        end
      end

      # O(1) Property lookup by id. Returns nil when not found.
      def property_by_id(id)
        return nil unless id

        property_index[id]
      end

      def alias_eaid_for_package(idx, package)
        return unless package.id&.start_with?("EAPK_")

        idx["EAID_#{package.id[5..]}"] = package
      end

      def root_packages
        packages.select { |p| p.parent_id.nil? }
      end

      def classifiers_in_package(package_id)
        classifiers.select { |c| c.package_id == package_id }
      end

      def relationships_for(classifier_id)
        relationships.select do |r|
          case r
          when Association
            r.source_id == classifier_id || r.target_id == classifier_id
          when Generalization
            r.specific_id == classifier_id || r.general_id == classifier_id
          when Realization
            r.realizing_id == classifier_id || r.contract_id == classifier_id
          when Dependency
            r.client_id == classifier_id || r.supplier_id == classifier_id
          else
            false
          end
        end
      end

      def reset_indexes
        @index_by_id = nil
        @property_index = nil
      end

      json do
        map "metadata", to: :metadata
        map "packages", to: :packages, render_empty: true
        map "classifiers", to: :classifiers, render_empty: true,
                           polymorphic: CLASSIFIER_POLYMORPHIC_MAP
        map "relationships", to: :relationships, render_empty: true,
                             polymorphic: RELATIONSHIP_POLYMORPHIC_MAP
        map "stereotypes", to: :stereotypes, render_empty: true
        map "notes", to: :notes, render_empty: true
        map "instanceSpecifications", to: :instance_specifications,
            render_empty: true
        map "diagrams", to: :diagrams, render_empty: true
      end
    end
  end
end
