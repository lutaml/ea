# frozen_string_literal: true

require "nokogiri"
require "xmi"
require "liquid"
require "cgi"

module Ea
  module Xmi
    autoload :Parser, "ea/xmi/parser"
    autoload :LookupService, "ea/xmi/lookup_service"

    module LiquidDrops
      autoload :RootDrop, "ea/xmi/liquid_drops/root_drop"
      autoload :PackageDrop, "ea/xmi/liquid_drops/package_drop"
      autoload :KlassDrop, "ea/xmi/liquid_drops/klass_drop"
      autoload :AttributeDrop, "ea/xmi/liquid_drops/attribute_drop"
      autoload :OperationDrop, "ea/xmi/liquid_drops/operation_drop"
      autoload :AssociationDrop, "ea/xmi/liquid_drops/association_drop"
      autoload :GeneralizationDrop, "ea/xmi/liquid_drops/generalization_drop"
      autoload :GeneralizationAttributeDrop,
               "ea/xmi/liquid_drops/generalization_attribute_drop"
      autoload :DependencyDrop, "ea/xmi/liquid_drops/dependency_drop"
      autoload :ConstraintDrop, "ea/xmi/liquid_drops/constraint_drop"
      autoload :DiagramDrop, "ea/xmi/liquid_drops/diagram_drop"
      autoload :EnumDrop, "ea/xmi/liquid_drops/enum_drop"
      autoload :EnumOwnedLiteralDrop,
               "ea/xmi/liquid_drops/enum_owned_literal_drop"
      autoload :DataTypeDrop, "ea/xmi/liquid_drops/data_type_drop"
      autoload :CardinalityDrop, "ea/xmi/liquid_drops/cardinality_drop"
      autoload :ConnectorDrop, "ea/xmi/liquid_drops/connector_drop"
      autoload :SourceTargetDrop, "ea/xmi/liquid_drops/source_target_drop"
    end
  end
end
