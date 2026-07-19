# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Maps EA's `t_connector.Connector_Type` discriminator to the
      # concrete Ea::Model::Relationship subclass. Adds new
      # relationship kinds by registering here (OCP).
      module ConnectorRelationshipMap
        module_function

        LOOKUP = {
          "Association" => "Ea::Model::Association",
          "Aggregation" => "Ea::Model::Association",
          "Composition" => "Ea::Model::Association",
          "Generalization" => "Ea::Model::Generalization",
          "Realization" => "Ea::Model::Realization",
          "Usage" => "Ea::Model::Dependency",
          "Dependency" => "Ea::Model::Dependency",
          "Abstraction" => "Ea::Model::Dependency"
        }.freeze

        # Some connector types imply specific aggregation values on
        # the source end (EA stores them as separate Connector_Type
        # values rather than as an attribute on the connector).
        AGGREGATION_FOR = {
          "Aggregation" => "shared",
          "Composition" => "composite"
        }.freeze

        def class_for(connector_type)
          name = LOOKUP[connector_type] || "Ea::Model::Association"
          Object.const_get(name)
        end

        def source_aggregation_for(connector_type)
          AGGREGATION_FOR[connector_type] || "none"
        end
      end
    end
  end
end
