# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Maps XMI's `xmi:type` discriminator on packaged elements to
      # the concrete Ea::Model::Classifier subclass. New classifier
      # kinds = one entry here, nothing else changes (OCP).
      module TypeClassifierMap
        module_function

        LOOKUP = {
          "uml:Class" => "Ea::Model::Klass",
          "uml:DataType" => "Ea::Model::DataType",
          "uml:PrimitiveType" => "Ea::Model::PrimitiveType",
          "uml:Enumeration" => "Ea::Model::Enumeration",
          "uml:Interface" => "Ea::Model::Interface",
        }.freeze

        def class_for(xmi_type)
          name = LOOKUP[xmi_type]
          return nil unless name

          Object.const_get(name)
        end

        def classifier_type?(xmi_type)
          LOOKUP.key?(xmi_type)
        end
      end
    end
  end
end
