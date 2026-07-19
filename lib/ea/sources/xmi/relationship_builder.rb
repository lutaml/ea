# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Translates XMI relationship elements (uml:Association,
      # uml:Generalization, uml:Realization, uml:Dependency) into
      # the appropriate Ea::Model::Relationship subclass.
      class RelationshipBuilder
        attr_reader :root

        def initialize(root)
          @root = root
        end

        def build_all
          relationships = []
          walk(root.model) do |element|
            next unless RelationshipTypeMap.relationship_type?(element.type)

            rel = build_one(element)
            relationships << rel if rel
          end
          relationships
        end

        def build_one(element)
          klass = RelationshipTypeMap.class_for(element.type)
          args = common_args(element)
          args.merge!(specific_args_for(klass, element))
          klass.new(**args)
        end

        private

        def walk(element, &block)
          yield element if block
          element.packaged_element.each { |inner| walk(inner, &block) }
        end

        def common_args(element)
          id = IdNormalizer.from_xmi_id(element.id)
          {
            id: id,
            name: element.name || element.type&.split(":")&.last&.downcase,
            qualified_name: element.name,
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
            source_navigable: navigable?(source_end),
            target_navigable: navigable?(target_end)
          }
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

        def navigable?(end_element)
          return true unless end_element

          # XMI represents non-navigable ends with aggregation=none
          # and no role name; treat presence of role name or any
          # aggregation as navigable. Default: navigable.
          true
        end
      end
    end
  end
end
