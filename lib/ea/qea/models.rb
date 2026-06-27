# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Qea
    module Models
      autoload :BaseModel, "ea/qea/models/base_model"
      autoload :EaAttribute, "ea/qea/models/ea_attribute"
      autoload :EaAttributeTag, "ea/qea/models/ea_attribute_tag"
      autoload :EaComplexityType, "ea/qea/models/ea_complexity_type"
      autoload :EaConnector, "ea/qea/models/ea_connector"
      autoload :EaConnectorType, "ea/qea/models/ea_connector_type"
      autoload :EaConstraintType, "ea/qea/models/ea_constraint_type"
      autoload :EaDatatype, "ea/qea/models/ea_datatype"
      autoload :EaDiagram, "ea/qea/models/ea_diagram"
      autoload :EaDiagramLink, "ea/qea/models/ea_diagram_link"
      autoload :EaDiagramObject, "ea/qea/models/ea_diagram_object"
      autoload :EaDiagramType, "ea/qea/models/ea_diagram_type"
      autoload :EaDocument, "ea/qea/models/ea_document"
      autoload :EaObject, "ea/qea/models/ea_object"
      autoload :EaObjectConstraint, "ea/qea/models/ea_object_constraint"
      autoload :EaObjectProperty, "ea/qea/models/ea_object_property"
      autoload :EaObjectType, "ea/qea/models/ea_object_type"
      autoload :EaOperation, "ea/qea/models/ea_operation"
      autoload :EaOperationParam, "ea/qea/models/ea_operation_param"
      autoload :EaPackage, "ea/qea/models/ea_package"
      autoload :EaScript, "ea/qea/models/ea_script"
      autoload :EaStatusType, "ea/qea/models/ea_status_type"
      autoload :EaStereotype, "ea/qea/models/ea_stereotype"
      autoload :EaTaggedValue, "ea/qea/models/ea_tagged_value"
      autoload :EaXref, "ea/qea/models/ea_xref"
    end
  end
end
