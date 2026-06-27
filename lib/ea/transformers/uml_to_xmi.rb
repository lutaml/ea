# frozen_string_literal: true

module Ea
  module Transformers
    # Lossy transformer: Lutaml::Uml::Document → Sparx XMI.
    #
    # Use this when the source is a tool-agnostic UML model (from LML,
    # MagicDraw, Papyrus, etc.) and some information loss is acceptable.
    # For Sparx QEA → Sparx XMI, use {Ea::Transformers::QeaToXmi} instead.
    module UmlToXmi
      autoload :Transformer, "ea/transformers/uml_to_xmi/transformer"
      autoload :Writer,      "ea/transformers/uml_to_xmi/writer"
      autoload :IdGenerator, "ea/transformers/uml_to_xmi/id_generator"
    end
  end
end
