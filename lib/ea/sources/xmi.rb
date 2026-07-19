# frozen_string_literal: true

module Ea
  module Sources
    # XMI source adapter. Mirrors Ea::Sources::Qea: produces an
    # Ea::Model::Document from a parsed Xmi::Sparx::Root by walking
    # the UML model tree once and translating each element into the
    # canonical model.
    #
    # Both adapters emit structurally identical Ea::Model instances
    # — source format becomes irrelevant once you're in the model.
    # That's the "single way of doing things": one pipeline, two
    # interchangeable sources.
    module Xmi
      autoload :IdNormalizer, "ea/sources/xmi/id_normalizer"
      autoload :TypeClassifierMap, "ea/sources/xmi/type_classifier_map"
      autoload :RelationshipTypeMap, "ea/sources/xmi/relationship_type_map"
      autoload :MetadataBuilder, "ea/sources/xmi/metadata_builder"
      autoload :PackageBuilder, "ea/sources/xmi/package_builder"
      autoload :ClassifierBuilder, "ea/sources/xmi/classifier_builder"
      autoload :PropertyBuilder, "ea/sources/xmi/property_builder"
      autoload :OperationBuilder, "ea/sources/xmi/operation_builder"
      autoload :RelationshipBuilder, "ea/sources/xmi/relationship_builder"
      autoload :AnnotationBuilder, "ea/sources/xmi/annotation_builder"
      autoload :DiagramBuilder, "ea/sources/xmi/diagram_builder"
      autoload :Adapter, "ea/sources/xmi/adapter"
    end
  end
end
