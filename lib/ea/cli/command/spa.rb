# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea spa FILE [--output=PATH] [--mode=MODE]`
      #
      # Generates a static single-page application (SPA) from a QEA,
      # XMI, or LUR file. The SPA shows the package hierarchy, class
      # details, diagram list, and member navigation in a browser.
      #
      # Pipeline:
      #   1. Ea::Transformations.parse(file) → Lutaml::Uml::Document
      #   2. Lutaml::UmlRepository::Repository.from_document(document)
      #   3. Lutaml::UmlRepository::StaticSite::Generator.new(repo, ...).generate
      #
      # Output format defaults to single-file Vue IIFE HTML.
      class Spa < Base
        DEFAULT_MODE = :single_file

        def call
          repository = RepositoryBuilder.build_repository(file_path)

          require_lutaml_uml_static_site!
          strategy = resolve_output_strategy

          output_path = resolve_output_path
          options = {
            output: output_path,
            mode: mode,
            output_strategy: strategy,
          }.compact

          Lutaml::UmlRepository::StaticSite::Generator
            .new(repository, options)
            .generate

          formatter.render([[output_path]], columns: [:written_to])
        end

        private

        def mode
          (options[:mode] || DEFAULT_MODE).to_sym
        end

        def resolve_output_path
          options[:output] || default_output_path
        end

        def default_output_path
          base = File.basename(file_path, ".*")
          dir = File.dirname(file_path)
          File.join(dir, "#{base}.html")
        end

        def resolve_output_strategy
          case mode
          when :single_file, "single_file"
            Lutaml::UmlRepository::StaticSite::Output::VueInlinedStrategy
          when :multi_file, "multi_file"
            Lutaml::UmlRepository::StaticSite::Output::MultiFileStrategy
          else
            raise Ea::Cli::UnsupportedFormat,
                  "Unknown spa mode '#{mode}': use single_file or multi_file"
          end
        end

        def require_lutaml_uml_static_site!
          require "lutaml/uml_repository/static_site"
        rescue LoadError => e
          raise Ea::Cli::MissingUmlDependency,
                "spa command requires the `lutaml-uml` gem. " \
                "Install it via `gem install lutaml-uml`. (#{e.message})"
        end
      end
    end
  end
end
