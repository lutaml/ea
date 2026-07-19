# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Driving port: produces an Ea::Model::Document from a parsed
      # Ea::Qea::Database. Walks the SQLite-derived collections once
      # and delegates to per-domain builders (OCP/MECE — new model
      # types or source columns touch one builder).
      class Adapter
        attr_reader :database, :qea_path

        def initialize(database, qea_path = nil)
          @database = database
          @qea_path = qea_path
        end

        # Convenience: build a document directly from a .qea file
        # path. The file is parsed via the existing Ea::Qea pipeline.
        def self.from_path(qea_path)
          new(Ea.parse(qea_path), qea_path).to_document
        end

        def to_document
          Ea::Model::Document.new(
            metadata: metadata,
            packages: packages,
            classifiers: classifiers,
            relationships: relationships,
            stereotypes: stereotypes,
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
          @classifiers ||= ClassifierBuilder.new(database).build_all
        end

        def relationships
          @relationships ||= RelationshipBuilder.new(database).build_all
        end

        def stereotypes
          @stereotypes ||= StereotypeBuilder.new(database).build_all
        end

        def diagrams
          @diagrams ||= DiagramBuilder.new(database).build_all
        end
      end
    end
  end
end
