# frozen_string_literal: true

module Ea
  module Export
    # XSD (XML Schema Definition) export namespace.
    #
    # Translates a parsed QEA/UML model into an XSD schema by:
    # 1. Reading GMLClassMapping.xml to learn how UML classes map to
    #    GML types (element/type/propertyType names).
    # 2. Reading GMLNamespaces.xml to learn target namespaces.
    # 3. Walking the model's classes and emitting `<xs:element>` +
    #    `<xs:complexType>` declarations for each.
    module Xsd
      autoload :ClassMapping, "ea/export/xsd/class_mapping"
      autoload :NamespaceRegistry, "ea/export/xsd/namespace_registry"
      autoload :Generator, "ea/export/xsd/generator"
    end
  end
end
