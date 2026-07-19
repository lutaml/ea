# frozen_string_literal: true

module Ea
  module Sources
    # QEA source adapter. Produces an Ea::Model::Document from a
    # parsed Ea::Qea::Database by walking the SQLite-derived tables
    # once and translating each row into a model instance.
    #
    # Structure: Adapter coordinates per-domain Builders. Each
    # Builder owns one source table → model type translation, so
    # new model types or new source columns only touch one Builder
    # (OCP/MECE).
    module Qea
      autoload :IdNormalizer, "ea/sources/qea/id_normalizer"
      autoload :ObjectClassifierMap, "ea/sources/qea/object_classifier_map"
      autoload :ConnectorRelationshipMap, "ea/sources/qea/connector_relationship_map"
      autoload :MetadataBuilder, "ea/sources/qea/metadata_builder"
      autoload :PackageBuilder, "ea/sources/qea/package_builder"
      autoload :ClassifierBuilder, "ea/sources/qea/classifier_builder"
      autoload :PropertyBuilder, "ea/sources/qea/property_builder"
      autoload :OperationBuilder, "ea/sources/qea/operation_builder"
      autoload :RelationshipBuilder, "ea/sources/qea/relationship_builder"
      autoload :StereotypeBuilder, "ea/sources/qea/stereotype_builder"
      autoload :TaggedValueBuilder, "ea/sources/qea/tagged_value_builder"
      autoload :AnnotationBuilder, "ea/sources/qea/annotation_builder"
      autoload :DiagramBuilder, "ea/sources/qea/diagram_builder"
      autoload :DiagramStyleParser, "ea/sources/qea/diagram_style_parser"
      autoload :Adapter, "ea/sources/qea/adapter"
    end
  end
end
