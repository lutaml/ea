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
            instance_specifications: instance_specifications,
            diagrams: diagrams
          )
          mark_connector_proxies(doc)
          apply_tagged_values(doc)
          apply_constraints(doc)
          apply_receptions(doc)
          apply_stereotypes(doc)
          resolve_type_names(doc)
          doc
        end

        private

        # EA serializes connector anchors as UML class stubs. Keep their
        # identity and geometry while distinguishing their graphical role.
        def mark_connector_proxies(doc)
          proxy_ids = connector_proxy_ids
          return if proxy_ids.empty?

          doc.diagrams.flat_map(&:elements).each do |element|
            element.style["connector_proxy"] = true if proxy_ids.include?(element.model_element_ref)
          end
        end

        def connector_proxy_ids
          (root.extension&.elements&.element || []).filter_map do |element|
            IdNormalizer.from_xmi_id(element.idref) if element.type == "uml:ProxyConnector"
          end
        end

        def apply_receptions(doc)
          grouped = ReceptionBuilder.new(xmi_path).grouped_by_owner
          doc.classifiers.each do |classifier|
            classifier.operations.concat(grouped.fetch(classifier.id, []))
          end
        end

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

        # Attach the extension's element constraints to their classifiers,
        # as the QEA adapter does from t_objectconstraint.
        def apply_constraints(doc)
          grouped = ConstraintBuilder.new(xmi_path).grouped_by_element
          return if grouped.empty?

          doc.classifiers.each do |c|
            c.constraints = grouped[c.id] if c.id && grouped[c.id]
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

        # Replaces each type reference with the type name EA stores in
        # the extension block; references the extension does not name
        # fall back to the classifier's in-model qualified name.
        def resolve_type_names(doc)
          qualified_by_id = doc.classifiers.each_with_object({}) do |c, acc|
            acc[c.id] = c.qualified_name if c.id && c.qualified_name
          end
          types = ExtensionTypes.from_path(xmi_path)

          doc.classifiers.each do |classifier|
            (classifier.properties || []).each do |prop|
              prop.type_name = types.attribute_type(prop.id) ||
                               qualified_by_id[prop.type_ref] || prop.type_name
              apply_attribute_stereotype(prop, types)
            end
            (classifier.operations || []).each do |op|
              resolve_operation_types(op, qualified_by_id, types)
            end
          end
        end

        def apply_attribute_stereotype(prop, types)
          stereotype = types.attribute_stereotype(prop.id)
          return if stereotype.nil? || prop.stereotype_refs.to_a.any?

          prop.stereotype_refs = [stereotype]
        end

        def resolve_operation_types(operation, qualified_by_id, types)
          operation.return_type_name = types.return_type(operation.id) ||
                                       qualified_by_id[operation.return_type_name] ||
                                       operation.return_type_name
          operation.parameters.each do |param|
            param.type_name = types.parameter_type(param.id) ||
                              qualified_by_id[param.type_name] || param.type_name
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

        def instance_specifications
          @instance_specifications ||= InstanceBuilder.new(root, xmi_path, classifiers).build_all
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
