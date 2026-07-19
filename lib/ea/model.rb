# frozen_string_literal: true

require "lutaml/model"

module Ea
  # Ea::Model is the canonical domain model for what Sparx Enterprise
  # Architect models.
  #
  # It is intentionally independent of any source format. QEA and XMI
  # are translated into Ea::Model by source adapters
  # (Ea::Sources::Qea, Ea::Sources::Xmi). Consumers (Ea::Spa, future
  # exporters, validators, differs) project from Ea::Model — they do
  # not redefine the modeling types.
  #
  # Architectural principle: Hexagonal / Ports & Adapters. Ea::Model
  # is the hexagon. Source adapters are driving ports; consumer
  # adapters are driven ports. Dependencies point inward only.
  module Model
    autoload :Base, "ea/model/base"
    autoload :Metadata, "ea/model/metadata"
    autoload :Point, "ea/model/point"
    autoload :Bounds, "ea/model/bounds"
    autoload :Waypoint, "ea/model/waypoint"
    autoload :Annotation, "ea/model/annotation"
    autoload :TaggedValue, "ea/model/tagged_value"
    autoload :Stereotype, "ea/model/stereotype"
    autoload :EnumerationLiteral, "ea/model/enumeration_literal"
    autoload :Parameter, "ea/model/parameter"
    autoload :Property, "ea/model/property"
    autoload :Operation, "ea/model/operation"
    autoload :Classifier, "ea/model/classifier"
    autoload :Klass, "ea/model/klass"
    autoload :DataType, "ea/model/data_type"
    autoload :PrimitiveType, "ea/model/primitive_type"
    autoload :Interface, "ea/model/interface"
    autoload :Enumeration, "ea/model/enumeration"
    autoload :Package, "ea/model/package"
    autoload :Relationship, "ea/model/relationship"
    autoload :Association, "ea/model/association"
    autoload :Generalization, "ea/model/generalization"
    autoload :Realization, "ea/model/realization"
    autoload :Dependency, "ea/model/dependency"
    autoload :DiagramElement, "ea/model/diagram_element"
    autoload :DiagramConnector, "ea/model/diagram_connector"
    autoload :Diagram, "ea/model/diagram"
    autoload :Document, "ea/model/document"
  end
end
