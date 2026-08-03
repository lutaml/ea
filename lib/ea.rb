# frozen_string_literal: true

module Ea
  # Gem release version. Inlined here so lib/ea.rb has zero load-time
  # `require_relative` calls — the canonical "no require_relative for
  # internal library code" rule. The gemspec reads this constant
  # directly when bundler loads the gemspec via `require_relative`.
  VERSION = "0.5.0"

  class Error < StandardError; end

  autoload :Qea, "ea/qea"
  autoload :Model, "ea/model"
  autoload :Sources, "ea/sources"
  autoload :Spa, "ea/spa"
  autoload :Svg, "ea/svg"
  autoload :Theme, "ea/theme"
  autoload :Diagram, "ea/diagram"
  autoload :Transformations, "ea/transformations"
  autoload :Xmi, "ea/xmi"
  autoload :Transformers, "ea/transformers"
  autoload :Bridge, "ea/bridge"
  autoload :Cli, "ea/cli"
  autoload :Mdg, "ea/mdg"
  autoload :Diff, "ea/diff"
  autoload :Image, "ea/image"
  autoload :Export, "ea/export"
  autoload :Render, "ea/render"
  autoload :Shapescript, "ea/shapescript"
  autoload :Lint, "ea/lint"
  autoload :Query, "ea/query"
  autoload :Ocl, "ea/ocl"

  class << self
    # Parse an EA file into its native representation.
    #
    # Pure entry point — does NOT require the optional `lutaml-uml`
    # gem. The return type depends on the input format:
    #
    #   .qea → Ea::Qea::Database (Sparx SQLite tables as Ruby models)
    #   .xmi → Xmi::Sparx::Root   (typed Sparx XMI model from the xmi gem)
    #
    # @param path [String] path to a .qea or .xmi file
    # @return [Ea::Qea::Database, Xmi::Sparx::Root]
    def parse(path)
      Transformations.parse(path)
    end

    # Transform an EA file (or pre-parsed model) into a
    # `Lutaml::Uml::Document`.
    #
    # Bridge entry point — requires the optional `lutaml-uml` gem.
    # Used for cross-vendor UML output (e.g. EA → PlantUML via the
    # tool-agnostic UML metamodel). The lutaml-uml dependency is
    # lazy-required on first call.
    #
    # @param path_or_model [String, Ea::Qea::Database, Xmi::Sparx::Root]
    # @return [Lutaml::Uml::Document]
    def to_uml(path_or_model)
      Transformations.to_uml(path_or_model)
    end
  end
end
