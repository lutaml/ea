# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Translates XMI relationship elements (uml:Association,
      # uml:Generalization, uml:Realization, uml:Dependency) into
      # the appropriate Ea::Model::Relationship subclass.
      class RelationshipBuilder
        # Connector types that imply an aggregation on the source end
        # when the end itself records none.
        CONNECTOR_STEREOTYPE = /(?<=@STEREO;Name=)[^;]+/

        AGGREGATION_FOR_CONNECTOR_TYPE = {
          "Aggregation" => "shared",
          "Composition" => "composite"
        }.freeze

        attr_reader :root

        def initialize(root)
          @root = root
        end

        def build_all
          relationships = []
          root.model.packaged_element.each do |top|
            walk(top) do |element|
              relationships << build_one(element) if RelationshipTypeMap.relationship_type?(element.type)
              relationships.concat(owned_generalizations(element))
            end
          end
          relationships + package_import_relationships(relationships)
        end

        def build_one(element)
          klass = RelationshipTypeMap.class_for(element.type)
          args = common_args(element)
          args.merge!(specific_args_for(klass, element))
          klass.new(**args)
        end

        private

        def package_import_relationships(built)
          built_ids = built.to_set(&:id)
          connector_index.filter_map do |id, connector|
            next if built_ids.include?(id)

            extension_import_relationship(id, connector)
          end
        end

        def extension_import_relationship(id, connector)
          case connector.properties&.ea_type
          when "Package" then package_import_relationship(id, connector)
          when "Dependency"
            dependency_import_relationship(id, connector) if connector_stereotype(connector) == "import"
          end
        end

        # EA exports elementImport outside packagedElement, so the model walk
        # misses it; the extension retains the importing/imported endpoints.
        def dependency_import_relationship(id, connector)
          Ea::Model::Dependency.new(
            id: id, stereotype: "import",
            client_id: connector.source&.idref,
            supplier_id: connector.target&.idref
          )
        end

        def connector_stereotype(connector)
          connector&.xrefs&.value.to_s[CONNECTOR_STEREOTYPE]
        end

        def package_import_relationship(id, connector)
          Ea::Model::Association.new(
            id: id,
            stereotype: connector_stereotype(connector),
            source_id: connector.source&.idref,
            target_id: connector.target&.idref,
            source_navigable: navigable?(id, :source),
            target_navigable: navigable?(id, :target)
          )
        end

        def walk(element, &block)
          yield element if block
          element.packaged_element.each { |inner| walk(inner, &block) }
          element.nested_classifier.each { |inner| walk(inner, &block) }
        end

        def owned_generalizations(element)
          element.generalization.map do |generalization|
            Ea::Model::Generalization.new(
              id: IdNormalizer.from_xmi_id(generalization.id),
              specific_id: IdNormalizer.from_xmi_id(element.id),
              general_id: IdNormalizer.from_xmi_id(generalization.general)
            )
          end
        end

        def common_args(element)
          id = IdNormalizer.from_xmi_id(element.id)
          {
            id: id,
            name: element.name,
            qualified_name: element.name,
            stereotype: connector_stereotype(connector_index[id]),
            annotations: AnnotationBuilder.from_element(element, id)
          }
        end

        def specific_args_for(klass, element)
          case klass.name
          when "Ea::Model::Association" then association_args(element)
          when "Ea::Model::Generalization" then generalization_args(element)
          when "Ea::Model::Realization" then realization_args(element)
          when "Ea::Model::Dependency" then dependency_args(element)
          else {}
          end
        end

        def association_args(element)
          connector = connector_index[element.id]
          return owned_end_args(element) unless connector&.source && connector.target

          connector_end_args(element, connector)
        end

        def connector_end_args(element, connector)
          source = connector.source
          target = connector.target
          {
            source_id: source.idref,
            target_id: target.idref,
            source_role_name: source.role&.name,
            target_role_name: target.role&.name,
            source_multiplicity_lower: card_lower(source.type&.multiplicity),
            source_multiplicity_upper: card_upper(source.type&.multiplicity),
            target_multiplicity_lower: card_lower(target.type&.multiplicity),
            target_multiplicity_upper: card_upper(target.type&.multiplicity),
            source_multiplicity_raw: raw_card(source.type&.multiplicity),
            target_multiplicity_raw: raw_card(target.type&.multiplicity),
            source_aggregation: source_aggregation(connector),
            target_aggregation: target.type&.aggregation || "none",
            source_navigable: navigable?(element.id, :source),
            target_navigable: navigable?(element.id, :target)
          }
        end

        def source_aggregation(connector)
          flagged = connector.source.type&.aggregation || "none"
          return flagged unless flagged == "none"

          AGGREGATION_FOR_CONNECTOR_TYPE.fetch(connector.properties&.ea_type, "none")
        end

        def owned_end_args(element)
          ends = element.member_ends.to_a
          source_id = ends.first&.idref
          target_id = ends.last&.idref
          owned_ends = element.owned_end.to_a
          source_end = owned_ends.first
          target_end = owned_ends.last
          {
            source_id: source_id,
            target_id: target_id,
            source_role_name: source_end&.name,
            target_role_name: target_end&.name,
            source_multiplicity_lower: parse_lower(source_end),
            source_multiplicity_upper: parse_upper(source_end),
            target_multiplicity_lower: parse_lower(target_end),
            target_multiplicity_upper: parse_upper(target_end),
            source_aggregation: source_end&.aggregation || "none",
            target_aggregation: target_end&.aggregation || "none",
            source_navigable: navigable?(element.id, :source),
            target_navigable: navigable?(element.id, :target)
          }
        end

        def raw_card(cardinality)
          text = cardinality.to_s.strip
          text.empty? ? nil : text
        end

        def card_lower(cardinality)
          text = raw_card(cardinality)
          Integer(text.split("..").first, exception: false) if text
        end

        def card_upper(cardinality)
          text = raw_card(cardinality)
          return nil unless text

          upper = text.split("..").last
          upper == "*" ? -1 : Integer(upper, exception: false)
        end

        def generalization_args(element)
          # PackagedElement#generalization is a collection of
          # AssociationGeneralization rows. The "specific" (child)
          # is the owning element; "general" (parent) is the
          # referenced id on each generalization row.
          gen = element.generalization.first
          {
            specific_id: IdNormalizer.from_xmi_id(element.id),
            general_id: gen&.general
          }
        end

        def realization_args(element)
          {
            realizing_id: element.client,
            contract_id: element.supplier
          }
        end

        def dependency_args(element)
          {
            client_id: element.client,
            supplier_id: element.supplier
          }
        end

        def parse_lower(end_element)
          return 1 unless end_element

          value = end_element.lower_value
          return 1 unless value

          Integer(value.value) rescue 1
        end

        def parse_upper(end_element)
          return 1 unless end_element

          value = end_element.upper_value
          return 1 unless value

          raw = value.value
          return -1 if raw.to_s == "*"

          Integer(raw) rescue 1
        end

        def connector_index
          @connector_index ||= begin
            connectors = root.extension&.connectors&.connector || []
            connectors.each_with_object({}) do |connector, index|
              index[connector.idref] = connector if connector.idref
            end
          end
        end

        def navigable?(id, endpoint)
          connector = connector_index[id]
          end_element = connector&.public_send(endpoint)
          flag = end_element&.modifiers&.is_navigable
          flag.nil? || flag
        end
      end
    end
  end
end
