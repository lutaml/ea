# frozen_string_literal: true

module Ea
  module Qea
    module Validation
      autoload :ValidationMessage, "ea/qea/validation/validation_message"
      autoload :ValidationResult, "ea/qea/validation/validation_result"
      autoload :BaseValidator, "ea/qea/validation/base_validator"
      autoload :ValidatorRegistry, "ea/qea/validation/validator_registry"
      autoload :AssociationValidator,
               "ea/qea/validation/association_validator"
      autoload :AttributeValidator, "ea/qea/validation/attribute_validator"
      autoload :ClassValidator, "ea/qea/validation/class_validator"
      autoload :DiagramValidator, "ea/qea/validation/diagram_validator"
      autoload :OperationValidator, "ea/qea/validation/operation_validator"
      autoload :PackageValidator, "ea/qea/validation/package_validator"
      autoload :ReferentialIntegrityValidator,
               "ea/qea/validation/database/referential_integrity_validator"
      autoload :OrphanValidator,
               "ea/qea/validation/database/orphan_validator"
      autoload :CircularReferenceValidator,
               "ea/qea/validation/database/circular_reference_validator"
      autoload :Database, "ea/qea/validation/database"
      autoload :Formatters, "ea/qea/validation/formatters"
      autoload :ValidationEngine, "ea/qea/validation/validation_engine"
    end
  end
end
