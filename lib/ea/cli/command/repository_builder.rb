# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # Shared helper for building a `Lutaml::UmlRepository::Repository`
      # from any file format supported by `Ea::Transformations`.
      #
      # Single source of truth for "QEA/XMI/LUR → Repository" wiring.
      # Used by `Ea::Cli::Command::Diagrams` (extract action) and
      # `Ea::Cli::Command::Spa` (SPA generation).
      #
      # `.lur` files take the fast path via `Repository.from_file` (the
      # native LUR loader). QEA/XMI files are parsed via
      # `Ea::Transformations.parse` and wrapped via
      # `Repository.from_document`.
      module RepositoryBuilder
        LUR_EXT = ".lur".freeze

        module_function

        # @param path [String] file path (QEA, XMI, or LUR)
        # @return [Lutaml::UmlRepository::Repository]
        def build_repository(path)
          require_lutaml_uml!

          if lur?(path)
            require_lutaml_uml_repository!
            return Lutaml::UmlRepository::Repository.from_file(path)
          end

          document = Ea::Transformations.to_uml(path)
          require_lutaml_uml_repository!
          Lutaml::UmlRepository::Repository.from_document(document)
        end

        def lur?(path)
          File.extname(path).downcase == LUR_EXT
        end

        # Loads the bridge gem. The lutaml-uml gem is an optional
        # dependency; if missing, raise the CLI's MissingUmlDependency
        # so the user gets a clear message about installing it.
        def require_lutaml_uml!
          require "lutaml/uml"
        rescue LoadError => e
          raise Ea::Cli::MissingUmlDependency,
                "spa and diagrams-extract commands require the " \
                "`lutaml-uml` gem. Install it via `gem install lutaml-uml` " \
                "or add it to your Gemfile. (#{e.message})"
        end

        def require_lutaml_uml_repository!
          require "lutaml/uml_repository"
        rescue LoadError => e
          raise Ea::Cli::MissingUmlDependency,
                "spa and diagrams-extract commands require the " \
                "`lutaml-uml` gem. Install it via `gem install lutaml-uml` " \
                "or add it to your Gemfile. (#{e.message})"
        end
      end
    end
  end
end
