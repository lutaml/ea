# frozen_string_literal: true

module Ea
  # Source adapters: translate format-specific parses (QEA SQLite,
  # Sparx XMI) into the canonical Ea::Model::Document.
  #
  # Each adapter is a driving port in the hexagonal sense — its
  # only job is to take a parsed source and emit model instances.
  # Adapters do not know about each other or about consumer
  # adapters (Ea::Spa, etc.).
  module Sources
    autoload :Qea, "ea/sources/qea"
    autoload :Xmi, "ea/sources/xmi"
  end
end
