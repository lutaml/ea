# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Driving port: produces an Ea::Model::Document from a parsed
      # Ea::Qea::Database. Walks the SQLite-derived collections once
      # and delegates to per-domain builders (OCP/MECE — new model
      # types or source columns touch one builder).
      class Adapter
        attr_reader :database, :qea_path, :mdg_registry

        def initialize(database, qea_path = nil, mdg_registry: nil)
          @database = database
          @qea_path = qea_path
          @mdg_registry = mdg_registry
        end

        # Convenience: build a document directly from a .qea file
        # path. The file is parsed via the existing Ea::Qea pipeline.
        #
        # mdg_registry: an optional Ea::Mdg::Registry. When provided,
        # ClassifierBuilder consults it to resolve inherited
        # attributes from MDG-defined parent classes (e.g. phantom
        # attributes like +lod1ImplicitRepresentation on CityGML
        # ImplicitGeometry, whose stereotype maps to an MDG class).
        def self.from_path(qea_path, mdg_registry: nil)
          new(Ea.parse(qea_path), qea_path, mdg_registry: mdg_registry).to_document
        end

        def to_document
          Ea::Model::Document.new(
            metadata: metadata,
            packages: packages,
            classifiers: classifiers,
            relationships: relationships,
            stereotypes: stereotypes,
            notes: notes,
            instance_specifications: instance_specifications,
            diagrams: diagrams
          )
        end

        private

        def metadata
          @metadata ||= MetadataBuilder.new(database, qea_path).build
        end

        def packages
          @packages ||= PackageBuilder.new(database).build_all
        end

        def classifiers
          @classifiers ||= ClassifierBuilder.new(database, mdg_registry: mdg_registry).build_all
        end

        def relationships
          @relationships ||= RelationshipBuilder.new(database).build_all
        end

        def stereotypes
          @stereotypes ||= StereotypeBuilder.new(database).build_all
        end

        def notes
          @notes ||= NoteBuilder.new(database).build_all
        end

        def instance_specifications
          @instance_specifications ||= InstanceBuilder.new(database).build_all
        end

        def diagrams
          @diagrams ||= DiagramBuilder.new(database).build_all
        end
      end
    end
  end
end
