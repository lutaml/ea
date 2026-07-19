# frozen_string_literal: true

module Ea
  module Model
    # Polymorphic dispatch maps for collections that hold subclasses
    # of an abstract base. The discriminator field carries the
    # concrete subclass name on every instance; lutaml-model uses
    # this map to pick the right class on deserialize.
    CLASSIFIER_POLYMORPHIC_MAP = {
      attribute: "modelKind",
      class_map: {
        "class" => "Ea::Model::Klass",
        "data_type" => "Ea::Model::DataType",
        "primitive_type" => "Ea::Model::PrimitiveType",
        "enumeration" => "Ea::Model::Enumeration",
        "interface" => "Ea::Model::Interface"
      }
    }.freeze

    RELATIONSHIP_POLYMORPHIC_MAP = {
      attribute: "relationshipKind",
      class_map: {
        "association" => "Ea::Model::Association",
        "generalization" => "Ea::Model::Generalization",
        "realization" => "Ea::Model::Realization",
        "dependency" => "Ea::Model::Dependency"
      }
    }.freeze
  end
end
