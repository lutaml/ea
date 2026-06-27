# frozen_string_literal: true

module Ea
  module Qea
    module Factory
      # Transforms EA objects (DataType type) to UML data types
      class DataTypeTransformer < BaseTransformer
        # Transform EA object to UML data type
        # @param ea_object [EaObject] EA object model
        # @return [Lutaml::Uml::DataType] UML data type
        def transform(ea_object) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
          return nil if ea_object.nil?
          return nil unless ea_object.data_type?

          Lutaml::Uml::DataType.new.tap do |data_type| # rubocop:disable Metrics/BlockLength
            # Map basic properties
            data_type.name = ea_object.name
            data_type.xmi_id = normalize_guid_to_xmi_format(ea_object.ea_guid,
                                                            "EAID")
            data_type.is_abstract = ea_object.abstract?
            data_type.type = "DataType"
            data_type.visibility = map_visibility(ea_object.visibility)

            # Map stereotype
            if ea_object.stereotype && !ea_object.stereotype.empty?
              data_type.stereotype = [ea_object.stereotype]
            end

            # Map definition/notes
            data_type.definition = ea_object.note unless
              ea_object.note.nil? || ea_object.note.empty?

            # Load and transform attributes
            data_type.attributes = load_attributes(ea_object.ea_object_id)

            # Load and transform operations
            data_type.operations = load_operations(ea_object.ea_object_id)

            # Load and transform constraints
            data_type.constraints = load_constraints(ea_object.ea_object_id)

            # Load and transform tagged values
            data_type.tagged_values = load_tagged_values(ea_object.ea_guid)

            # Load associations for this data type
            data_type.associations = load_associations(ea_object.ea_object_id,
                                                       ea_object.ea_guid)
          end
        end

        private

        # Load associations for a data type
        # @param object_id [Integer] Object ID
        # @param object_guid [String] Object GUID
        # @return [Array<Lutaml::Uml::Association>] UML associations
        def load_associations(object_id, object_guid) # rubocop:disable Metrics/MethodLength
          return [] if object_id.nil?

          assoc_connectors = database.connectors_for_object(object_id)
            .select { |c| c.connector_type == "Association" }

          assoc_transformer = AssociationTransformer.new(database)
          normalized_xmi_id = normalize_guid_to_xmi_format(object_guid, "EAID")

          assoc_connectors.filter_map do |ea_connector|
            assoc = assoc_transformer.transform(ea_connector)

            next unless assoc && assoc.owner_end_xmi_id == normalized_xmi_id

            assoc
          end
        end
      end
    end
  end
end
