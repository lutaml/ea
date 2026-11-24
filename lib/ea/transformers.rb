# frozen_string_literal: true

module Ea
  # Output transformers — converts domain models to interchange formats.
  #
  # Single entry point:
  #
  #   {qea_to_xmi} — full fidelity, takes an Ea::Qea::Database
  #                  (Sparx-to-Sparx round-trip)
  module Transformers
    autoload :QeaToXmi, "ea/transformers/qea_to_xmi"

    class << self
      # Full fidelity: Ea::Qea::Database → Sparx XMI.
      # Walks the QEA tables directly — no intermediate UML model, no loss of
      # Sparx-specific concepts (stereotypes, tagged values, multiplicities,
      # diagrams, xrefs).
      #
      # @param database [Ea::Qea::Database]
      # @param with_extensions [Boolean] emit EA-specific connectors+diagrams
      # @param mdg_registry [Ea::Mdg::Registry, nil] when provided,
      #   stereotype definitions from registered MDG technologies are
      #   emitted as `<uml:Stereotype>` profile elements in the model
      #   tree. MDGs can be swapped in/out at runtime (OCP).
      # @return [String] XMI XML
      def qea_to_xmi(database, with_extensions: true, mdg_registry: nil)
        QeaToXmi::Transformer.new(database, mdg_registry: mdg_registry).serialize(with_extensions: with_extensions)
      end
    end
  end
end
