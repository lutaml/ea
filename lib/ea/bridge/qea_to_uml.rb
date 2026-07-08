# frozen_string_literal: true

module Ea
  module Bridge
    # Transforms an `Ea::Qea::Database` into a `Lutaml::Uml::Document`.
    #
    # This is the bridge between ea's internal EA-native representation
    # (the SQLite-derived row models) and the tool-agnostic UML
    # metamodel from `lutaml-uml`.
    #
    # The heavy lifting is done by the existing factory classes under
    # `Ea::Qea::Factory::*`. This module is the clean public entry
    # point — consumers should call `Ea::Bridge::QeaToUml.transform(db)`
    # rather than reaching into the factory internals.
    module QeaToUml
      module_function

      # @param database [Ea::Qea::Database] loaded QEA database
      # @param options [Hash] transformation options
      # @return [Lutaml::Uml::Document]
      def transform(database, options = {})
        require_lutaml_uml!
        factory(database, options).create_document
      end

      def require_lutaml_uml!
        require "lutaml/uml"
      rescue LoadError => e
        raise Ea::Error,
              "Ea::Bridge requires the `lutaml-uml` gem. " \
              "Install it via `gem install lutaml-uml`. (#{e.message})"
      end

      def factory(database, options)
        Ea::Qea::Factory::EaToUmlFactory.new(database, options)
      end
    end
  end
end
