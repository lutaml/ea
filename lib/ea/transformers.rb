# frozen_string_literal: true

module Ea
  # Output transformers — converts domain models to interchange formats.
  #
  # Two entry points:
  #
  #   {uml_to_xmi} — lossy, takes a Lutaml::Uml::Document (cross-tool use)
  #   {qea_to_xmi} — full fidelity, takes an Ea::Qea::Database
  #                  (Sparx-to-Sparx round-trip)
  module Transformers
    autoload :UmlToXmi, "ea/transformers/uml_to_xmi"
    autoload :QeaToXmi, "ea/transformers/qea_to_xmi"

    class << self
      # Lossy: any Lutaml::Uml::Document → Sparx XMI (cross-tool).
      # @param document [Lutaml::Uml::Document]
      # @return [String] XMI XML
      def uml_to_xmi(document)
        UmlToXmi::Transformer.new(document).serialize
      end

      # Full fidelity: Ea::Qea::Database → Sparx XMI.
      # Walks the QEA tables directly — no intermediate UML model, no loss of
      # Sparx-specific concepts (stereotypes, tagged values, multiplicities,
      # diagrams, xrefs).
      # @param database [Ea::Qea::Database]
      # @return [String] XMI XML
      def qea_to_xmi(database)
        QeaToXmi::Transformer.new(database).serialize
      end
    end
  end
end
