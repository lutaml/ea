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
          doc = Ea::Model::Document.new(
            metadata: metadata,
            packages: packages,
            classifiers: classifiers,
            relationships: relationships,
            stereotypes: [],
            diagrams: diagrams
          )
          resolve_type_names(doc)
          doc
        end

        private

        def resolve_type_names(doc)
          id_index = doc.index_by_id
          name_index = doc.classifiers.each_with_object({}) do |c, acc|
            acc[c.id] = c.name if c.id && c.name
          end
          # Also index by EAID format from the raw XMI (some refs
          # use the full EAID_... guid)
          doc.classifiers.each do |c|
            next unless c.id

            name_index[c.id] = c.name
          end

          doc.classifiers.each do |classifier|
            (classifier.properties || []).each do |prop|
              next if prop.type_name.nil? || prop.type_name.empty?
              next unless prop.type_name.start_with?("EAID_")

              resolved = name_index[prop.type_name]
              if resolved
                prop.type_name = resolved
              else
                prop.type_name = nil
              end
            end
          end
        end

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
