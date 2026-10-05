# frozen_string_literal: true

require "nokogiri"
require "xmi"
require "liquid"
require "cgi"

module Ea
  module Xmi
    autoload :Parser, "ea/xmi/parser"
    autoload :LookupService, "ea/xmi/lookup_service"
    autoload :Slicer, "ea/xmi/slicer"
    autoload :Loader, "ea/xmi/loader"
    autoload :Loaded, "ea/xmi/loader"

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

    module_function

    # Parse an XMI file into the xmi gem's typed Sparx model.
    #
    # Pure entry point — does NOT require `lutaml-uml`. Returns the
    # `Xmi::Sparx::Root` model tree from the `xmi` gem. This is the
    # internal EA-native representation for XMI files.
    #
    # To get a `Lutaml::Uml::Document` instead (requires the optional
    # `lutaml-uml` gem), use `Ea::Bridge::XmiToUml.transform(root)`.
    #
    # @param path [String, IO] path to a .xmi file, or an IO
    # @param partial [Array, nil] wanted [package, name] pairs; when
    #   given, only the reference closure of those elements is parsed,
    #   assembled in memory (see Ea::Xmi::Slicer). Partial load
    #   produces the same content as whole load for everything derived
    #   from the model's elements; it exists so reading a handful of
    #   classes out of a large export does not hydrate the whole of
    #   it. Whole load is the default. package may be nil, matching by
    #   name in any package.
    # @return [Xmi::Sparx::Root]
    def load(path, partial: nil)
      Loader.call(path, partial: partial)
    end

    # Load an export into the parsed EA graph: the parser, the parsed
    # document, and the lookup indexes the table renders resolve
    # through. See #load for whole vs partial loading.
    #
    # @return [Ea::Xmi::Loaded]
    def load_graph(path, partial: nil)
      Loader.graph(path, partial: partial)
    end
  end
end
