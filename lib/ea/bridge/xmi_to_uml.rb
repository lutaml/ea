# frozen_string_literal: true

module Ea
  module Bridge
    # Transforms an `Xmi::Sparx::Root` (the xmi gem's typed Sparx XMI
    # model) into a `Lutaml::Uml::Document`.
    #
    # This is the bridge between ea's internal XMI representation
    # (the xmi gem's model tree) and the tool-agnostic UML metamodel
    # from `lutaml-uml`.
    #
    # The heavy lifting is done by the existing parser code in
    # `Ea::Xmi::Parser`. This module is the clean public entry point
    # — consumers should call `Ea::Bridge::XmiToUml.transform(root)`
    # rather than reaching into the parser internals.
    module XmiToUml
      module_function

      # @param xmi_root [Xmi::Sparx::Root] parsed xmi gem model
      # @return [Lutaml::Uml::Document]
      def transform(xmi_root)
        require_lutaml_uml!
        Ea::Xmi::Parser.new.parse(xmi_root)
      end

      def require_lutaml_uml!
        require "lutaml/uml"
      rescue LoadError => e
        raise Ea::Error,
              "Ea::Bridge requires the `lutaml-uml` gem. " \
              "Install it via `gem install lutaml-uml`. (#{e.message})"
      end
    end
  end
end
