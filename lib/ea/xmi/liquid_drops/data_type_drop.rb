# frozen_string_literal: true

module Ea
  module Xmi
    module LiquidDrops
      class DataTypeDrop < Liquid::Drop
        def initialize(model, guidance = nil, options = {}) # rubocop:disable Lint/MissingSuper
          @model = model
          @guidance = guidance
          @options = options
          @lookup = options[:lookup]
          @xmi_root_model = options[:xmi_root_model]

          init_guidance(guidance) if guidance
        end

        private

        def init_guidance(guidance)
          @data_type_guidance = guidance["data_types"]&.find do |data_type|
            data_type["name"] == name || data_type["name"] == absolute_path
          end
        end

        public

        def xmi_id
          @model.xmi_id
        end

        def name
          @model.name
        end

        def absolute_path
          absolute_path_arr = [@model.name]
          e = @lookup.find_upper_level_packaged_element(@model.xmi_id)
          absolute_path_arr << e.name if e

          while e
            e = @lookup.find_upper_level_packaged_element(e.id)
            absolute_path_arr << e.name if e
          end

          absolute_path_arr << "::#{@xmi_root_model.model.name}"
          absolute_path_arr.reverse.join("::")
        end

        def attributes
          Array(@model.attributes).filter_map do |owned_attr|
            if @options[:with_assoc] || owned_attr.association.nil?
              ::Ea::Xmi::LiquidDrops::AttributeDrop.new(owned_attr,
                                                            @options)
            end
          end
        end

        def operations
          Array(@model.operations).map do |operation|
            ::Ea::Xmi::LiquidDrops::OperationDrop.new(operation)
          end
        end

        def associations
          Array(@model.associations).filter_map do |assoc|
            ::Ea::Xmi::LiquidDrops::AssociationDrop.new(assoc, @options)
          end
        end

        def constraints
          Array(@model.constraints).map do |constraint|
            ::Ea::Xmi::LiquidDrops::ConstraintDrop.new(constraint)
          end
        end

        def is_abstract # rubocop:disable Naming/PredicateName,Naming/PredicatePrefix
          @model.is_abstract
        end

        def definition
          @model.definition
        end

        def stereotype
          @model.stereotype&.first
        end

        def owned_attributes
          Array(@model.attributes).filter_map do |owned_attr|
            ::Ea::Xmi::LiquidDrops::AttributeDrop.new(owned_attr, @options)
          end
        end

        def generalization
          if @model.generalization
            ::Ea::Xmi::LiquidDrops::GeneralizationDrop.new(
              @model.generalization, @data_type_guidance, @options
            )
          end
        end

        def has_guidance?
          !!@data_type_guidance
        end

        def upper_packaged_element
          e = @lookup.find_upper_level_packaged_element(@model.xmi_id)
          e&.name
        end

        def subtype_of
          @lookup.find_subtype_of_from_generalization(@model.xmi_id) ||
            @lookup.find_subtype_of_from_owned_attribute_type(@model.xmi_id)
        end

        def inheritances
          Array(@inheritance_ids).filter_map do |inheritance_id|
            connector = @lookup.fetch_connector(inheritance_id)
            ::Ea::Xmi::LiquidDrops::ConnectorDrop.new(connector, @options)
          end
        end
      end
    end
  end
end
