# frozen_string_literal: true

module Ea
  module Xmi
    module LiquidDrops
      class AttributeDrop < Liquid::Drop
        def initialize(model, options = {}, guidance = nil) # rubocop:disable Lint/MissingSuper
          @model = model
          @options = options
          @lookup = options[:lookup]
          @guidance = guidance
        end

        def id
          @model.id
        end

        def name
          @model.name
        end

        def type
          @model.type
        end

        def xmi_id
          @model.xmi_id
        end

        def is_derived # rubocop:disable Naming/PredicateName,Naming/PredicatePrefix
          @model.is_derived
        end

        def cardinality
          ::Ea::Xmi::LiquidDrops::CardinalityDrop.new(@model.cardinality)
        end

        def definition
          defn = if @options[:with_assoc] && @model.association
                   @lookup.lookup_assoc_def(@model.association)
                 else
                   @model.definition
                 end

          if defn.nil? || defn.empty?
            defn = @lookup.lookup_connector_def_by_associationclass(
              @model.association
            )
          end

          defn
        end

        def association
          return unless @options[:with_assoc] && @model.association

          @model.association
        end

        def association_connector
          return unless @model.association

          connector = @lookup.fetch_connector(@model.association)
          return unless connector

          ::Ea::Xmi::LiquidDrops::ConnectorDrop.new(connector, @options)
        end

        def type_ns
          return unless @options[:with_assoc] && @model.association

          @model.type_ns
        end

        def stereotype
          @lookup.doc_node_attribute_value(@model.xmi_id, "stereotype")
        end

        def used?
          if @guidance
            col_name = name
            attr = @guidance["attributes"].find { |a| a["name"] == col_name }
            return attr["used"].to_s if attr
          end

          "true"
        end

        def guidance
          return unless @guidance

          col_name = name
          attr = @guidance["attributes"].find { |a| a["name"] == col_name }

          attr["guidance"] if attr
        end
      end
    end
  end
end
