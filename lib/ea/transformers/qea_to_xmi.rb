# frozen_string_literal: true

module Ea
  module Transformers
    # Full-fidelity transformer: Ea::Qea::Database → Sparx XMI.
    #
    # Walks the package tree starting at root packages, building
    # Xmi::Sparx::Root / Xmi::Uml::UmlModel / Xmi::Uml::PackagedElement
    # models from each QEA row, then asks the xmi gem to serialize them
    # via `to_xml(use_prefix: true)` to produce Sparx XMI in the canonical
    # mixed-prefix style.
    #
    # Use this for Sparx-to-Sparx round-trip — no intermediate
    # Lutaml::Uml::Document, no loss of Sparx-specific concepts
    # (multiplicities, tagged values, stereotypes, primitive types,
    # instance specifications, association ends). For a tool-agnostic
    # UML document → XMI path, use UmlToXmi.
    module QeaToXmi
      autoload :Transformer,    "ea/transformers/qea_to_xmi/transformer"
      autoload :Context,        "ea/transformers/qea_to_xmi/context"
      autoload :IdAllocator,    "ea/transformers/qea_to_xmi/id_allocator"
      autoload :GuidFormat,     "ea/transformers/qea_to_xmi/guid_format"
      autoload :Cardinality,    "ea/transformers/qea_to_xmi/cardinality"
      autoload :Visibility,     "ea/transformers/qea_to_xmi/visibility"
      autoload :XmlSanitizer,   "ea/transformers/qea_to_xmi/xml_sanitizer"
      autoload :AssociationEnd, "ea/transformers/qea_to_xmi/association_end"
    end
  end
end
