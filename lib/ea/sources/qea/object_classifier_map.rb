# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Maps EA's `t_object.Object_Type` discriminator to the
      # concrete Ea::Model::Classifier subclass that should be
      # produced. New classifier kinds = one entry here, nothing
      # else changes (OCP).
      module ObjectClassifierMap
        module_function

        # EA Object_Type → Model class. Unknown types default to
        # Klass — the most generic classifier.
        LOOKUP = {
          "Class" => "Ea::Model::Klass",
          "DataType" => "Ea::Model::DataType",
          "Enumeration" => "Ea::Model::Enumeration",
          "Interface" => "Ea::Model::Interface",
          "PrimitiveType" => "Ea::Model::PrimitiveType",
          "Primitive" => "Ea::Model::PrimitiveType"
        }.freeze

        def class_for(object_type)
          name = LOOKUP[object_type] || "Ea::Model::Klass"
          Object.const_get(name)
        end

        def model_kind_for(object_type)
          cls = class_for(object_type)
          cls.new.model_kind
        end
      end
    end
  end
end
