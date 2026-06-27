# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # Shared base for all CLI commands.
      #
      # Provides:
      # - Options Hash access (read-only)
      # - Output formatter resolution from `:format` option
      # - Standalone QEA database loading (no lutaml-uml required)
      # - UML document parsing (lazy-loads lutaml-uml)
      # - File existence validation
      #
      # Subclasses implement {#call} and may use the protected helpers.
      class Base
        def initialize(options = {})
          @options = options
        end

        # Template method — subclasses implement.
        # @raise [NotImplementedError] if not overridden
        def call
          raise NotImplementedError, "#{self.class}#call not implemented"
        end

        protected

        attr_reader :options

        def formatter
          Ea::Cli::Output.instance_for(options[:format] || :table)
        end

        def file_path
          options[:file] or raise Ea::Cli::Error, "missing required --file"
        end

        # Load a QEA database. Works standalone — no lutaml-uml dependency.
        # @return [Ea::Qea::Database]
        def load_database(path = file_path)
          validate_file!(path)
          Ea::Qea.load(path)
        rescue Ea::Cli::Error
          raise
        rescue Ea::Error => e
          raise Ea::Cli::Error, "Failed to load #{path}: #{e.message}"
        end

        # Parse any EA file to a Lutaml::Uml::Document.
        # Lazy-loads lutaml-uml via Ea::Qea's require_uml! guard.
        # @return [Lutaml::Uml::Document]
        def parse_to_uml(path = file_path, **parse_options)
          validate_file!(path)
          Ea::Qea.parse(path, parse_options)
        rescue Ea::Cli::Error
          raise
        rescue Ea::Error => e
          if e.message.include?("lutaml-uml")
            raise Ea::Cli::MissingUmlDependency
          end

          raise Ea::Cli::Error, "Failed to parse #{path}: #{e.message}"
        end

        def validate_file!(path)
          raise Ea::Cli::FileNotFound, path unless File.exist?(path)
        end

        # Write content to a path; honors the `:output` option.
        # @return [String] the path written to
        def write_output(content, default_name:)
          path = options[:output] || default_name
          File.write(path, content)
          path
        end
      end
    end
  end
end
