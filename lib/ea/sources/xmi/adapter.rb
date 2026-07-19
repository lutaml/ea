# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Driving port: produces an Ea::Model::Document from a parsed
      # Xmi::Sparx::Root. Walks the UML model tree once and
      # delegates to per-domain builders. The result is structurally
      # identical to what the QEA adapter produces for the same
      # conceptual source — that's the "single way" promise.
      class Adapter
        attr_reader :root, :xmi_path

        def initialize(root, xmi_path = nil)
          @root = root
          @xmi_path = xmi_path
        end

        # Convenience: build a document directly from an .xmi file
        # path. Parses via Xmi::Sparx::Root.parse_xml.
        def self.from_path(xmi_path)
          require "xmi"
          root = ::Xmi::Sparx::Root.parse_xml(File.read(xmi_path))
          new(root, xmi_path).to_document
        end

        def to_document
          Ea::Model::Document.new(
            metadata: metadata,
            packages: packages,
            classifiers: classifiers,
            relationships: relationships,
            stereotypes: [],
            diagrams: diagrams
          )
        end

        private

        def metadata
          @metadata ||= MetadataBuilder.new(root, xmi_path).build
        end

        def packages
          @packages ||= PackageBuilder.new(root).build_all
        end

        def classifiers
          @classifiers ||= ClassifierBuilder.new(root).build_all
        end

        def relationships
          @relationships ||= RelationshipBuilder.new(root).build_all
        end

        def diagrams
          @diagrams ||= DiagramBuilder.new(root).build_all
        end
      end
    end
  end
end
