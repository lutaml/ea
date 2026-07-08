# frozen_string_literal: true

module Ea
  # The bridge namespace contains ALL code that depends on the
  # optional `lutaml-uml` gem. The rest of the ea gem is pure
  # Sparx EA parsing (QEA SQLite, Sparx XMI) and does NOT require
  # lutaml-uml.
  #
  # The bridge transforms ea's internal model representations:
  #
  #   Ea::Qea::Database  ──→  Lutaml::Uml::Document
  #   Xmi::Sparx::Root   ──→  Lutaml::Uml::Document
  #
  # This is the "transformation" layer for cross-vendor UML output.
  # It is NOT needed for:
  #   - Parsing QEA/XMI files
  #   - Converting QEA ↔ XMI (native Sparx round-trip)
  #   - Listing diagrams, elements, stats
  #
  # It IS needed for:
  #   - Generating a SPA (via lutaml-uml's StaticSite::Generator)
  #   - Rendering diagrams to SVG (via lutaml-uml's Repository)
  #   - Producing tool-agnostic UML output for non-Sparx consumers
  module Bridge
    autoload :QeaToUml, "ea/bridge/qea_to_uml"
    autoload :XmiToUml, "ea/bridge/xmi_to_uml"
  end
end
