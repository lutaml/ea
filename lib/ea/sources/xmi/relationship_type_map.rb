# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Maps XMI's `xmi:type` discriminator for relationship-shaped
      # packaged elements (uml:Association, uml:Generalization,
      # etc.) to the concrete Ea::Model::Relationship subclass.
      module RelationshipTypeMap
        module_function

        LOOKUP = {
          "uml:Association" => "Ea::Model::Association",
          "uml:Generalization" => "Ea::Model::Generalization",
          "uml:Realization" => "Ea::Model::Realization",
          "uml:Dependency" => "Ea::Model::Dependency",
          "uml:Usage" => "Ea::Model::Dependency",
          "uml:Abstraction" => "Ea::Model::Dependency",
        }.freeze

        def class_for(xmi_type)
          name = LOOKUP[xmi_type]
          return nil unless name

          Object.const_get(name)
        end

        def relationship_type?(xmi_type)
          LOOKUP.key?(xmi_type)
        end
      end
    end
  end
end
