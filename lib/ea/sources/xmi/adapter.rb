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
            notes: notes,
            diagrams: diagrams
          )
          apply_tagged_values(doc)
          apply_stereotypes(doc)
          resolve_type_names(doc)
          doc
        end

        private

        # Attach stereotypes parsed from <xmi:Extension>/<elements>
        # to their owning classifiers and packages.
        def apply_stereotypes(doc)
          grouped = StereotypeBuilder.new(root).grouped_by_element
          return if grouped.empty?

          doc.classifiers.each do |c|
            next unless c.id

            refs = grouped[c.id]
            next unless refs

            c.stereotype_refs = refs
          end
          doc.packages.each do |p|
            next unless p.id

            refs = grouped[p.id] || grouped["EAID_#{p.id[5..]}"]
            next unless refs

            p.stereotype_refs = refs
          end
        end

        # Attach tagged values parsed from the <xmi:Extension><tags>
        # block to their owning classifiers and packages.
        def apply_tagged_values(doc)
          grouped = TagBuilder.new(xmi_path).grouped_by_model_element
          return if grouped.empty?

          doc.classifiers.each do |c|
            next unless c.id

            tags = grouped[c.id]
            next unless tags

            c.tagged_values = tags
          end
          doc.packages.each do |p|
            next unless p.id

            tags = grouped[p.id] || grouped["EAID_#{p.id[5..]}"]
            next unless tags

            p.tagged_values = tags
          end
        end

        def resolve_type_names(doc)
          # In the XMI, the <type xmi:idref=...> is the type
          # classifier's GUID. The property's type_name was
          # pre-populated by PropertyBuilder with the same idref;
          # we replace it with the in-model qualified name when
          # the referenced classifier is loaded.
          qualified_by_id = doc.classifiers.each_with_object({}) do |c, acc|
            acc[c.id] = c.qualified_name if c.id && c.qualified_name
          end

          doc.classifiers.each do |classifier|
            (classifier.properties || []).each do |prop|
              ref = prop.type_ref
              next if ref.nil? || ref.empty?

              resolved = qualified_by_id[ref]
              prop.type_name = resolved if resolved
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
          @diagrams ||= DiagramBuilder.new(root, xmi_path).build_all
        end

        def notes
          @notes ||= NoteBuilder.new(root).build_all
        end
      end
    end
  end
end
