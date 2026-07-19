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
        "interface" => "Ea::Model::Interface"
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
      attribute :diagrams, Diagram, collection: true, initialize_empty: true

      # Flat lookup indexes, built lazily by consumers. Not
      # serialized — they're derived from the element collections.
      def index_by_id
        @index_by_id ||= begin
          idx = {}
          packages.each { |p| idx[p.id] = p }
          classifiers.each { |c| idx[c.id] = c }
          relationships.each { |r| idx[r.id] = r }
          stereotypes.each { |s| idx[s.id] = s }
          diagrams.each { |d| idx[d.id] = d }
          diagrams.each do |d|
            d.elements.each { |e| idx[e.id] = e }
            d.connectors.each { |c| idx[c.id] = c }
          end
          idx
        end
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
      end

      json do
        map "metadata", to: :metadata
        map "packages", to: :packages, render_empty: true
        map "classifiers", to: :classifiers, render_empty: true,
                           polymorphic: CLASSIFIER_POLYMORPHIC_MAP
        map "relationships", to: :relationships, render_empty: true,
                             polymorphic: RELATIONSHIP_POLYMORPHIC_MAP
        map "stereotypes", to: :stereotypes, render_empty: true
        map "diagrams", to: :diagrams, render_empty: true
      end
    end
  end
end
