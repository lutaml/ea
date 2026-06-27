# frozen_string_literal: true

module Ea
  module Qea
    module Factory
      autoload :BaseTransformer, "ea/qea/factory/base_transformer"
      autoload :AssociationBuilder, "ea/qea/factory/association_builder"
      autoload :AssociationTransformer,
               "ea/qea/factory/association_transformer"
      autoload :AttributeTagTransformer,
               "ea/qea/factory/attribute_tag_transformer"
      autoload :AttributeTransformer, "ea/qea/factory/attribute_transformer"
      autoload :ClassTransformer, "ea/qea/factory/class_transformer"
      autoload :ConstraintTransformer,
               "ea/qea/factory/constraint_transformer"
      autoload :DataTypeTransformer, "ea/qea/factory/data_type_transformer"
      autoload :DiagramTransformer, "ea/qea/factory/diagram_transformer"
      autoload :DocumentBuilder, "ea/qea/factory/document_builder"
      autoload :EnumTransformer, "ea/qea/factory/enum_transformer"
      autoload :GeneralizationBuilder,
               "ea/qea/factory/generalization_builder"
      autoload :GeneralizationTransformer,
               "ea/qea/factory/generalization_transformer"
      autoload :InstanceTransformer, "ea/qea/factory/instance_transformer"
      autoload :ObjectPropertyTransformer,
               "ea/qea/factory/object_property_transformer"
      autoload :OperationTransformer, "ea/qea/factory/operation_transformer"
      autoload :PackageTransformer, "ea/qea/factory/package_transformer"
      autoload :ReferenceResolver, "ea/qea/factory/reference_resolver"
      autoload :StereotypeLoader, "ea/qea/factory/stereotype_loader"
      autoload :TaggedValueTransformer,
               "ea/qea/factory/tagged_value_transformer"
      autoload :TransformerRegistry, "ea/qea/factory/transformer_registry"
      autoload :EaToUmlFactory, "ea/qea/factory/ea_to_uml_factory"
    end
  end
end
