# frozen_string_literal: true

# frozen_string: true

require "lutaml/model"

module Ea
  # MDG (Model Driven Generation) Technology support.
  #
  # EA's MDG technologies bundle UML profiles, reference models,
  # and toolbox definitions in a single XMI file. When EA loads
  # an MDG, the MDG's classes/attributes/stereotypes become
  # available to all models — including inherited attribute
  # rendering when a classifier's stereotype maps to an MDG-
  # defined metaclass.
  #
  # This namespace is standalone: it does not depend on QEA or
  # XMI source adapters. Source adapters OPTIONALLY consume an
  # Mdg::Registry to merge MDG-defined inherited attributes.
  module Mdg
    autoload :Document, "ea/mdg/document"
    autoload :Loader, "ea/mdg/loader"
    autoload :Registry, "ea/mdg/registry"
    autoload :StereotypeAliasRegistry, "ea/mdg/stereotype_alias_registry"
    autoload :Xml, "ea/mdg/xml"
  end
end
