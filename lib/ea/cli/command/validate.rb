# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea validate FILE`
      #
      # Runs Ea::Qea::Validation::ValidationEngine and reports messages.
      # Exits non-zero if any errors were found.
      #
      # Requires lutaml-uml (validation runs against Lutaml::Uml::Document).
      class Validate < Base
        COLUMNS = %i[severity entity_type entity_name message].freeze

        def call
          result = parse_with_validation(file_path)
          rows = result.messages.map do |m|
            [m.severity, m.entity_type, m.entity_name, m.message]
          end
          formatter.render(rows, columns: COLUMNS)
          exit(1) if result.errors.any?
        end

        private

        def parse_with_validation(path)
          validate_file!(path)
          Ea::Qea.parse(path, validate: true)[:validation_result]
        rescue Ea::Cli::Error
          raise
        rescue Ea::Error => e
          if e.message.include?("lutaml-uml")
            raise Ea::Cli::MissingUmlDependency
          end

          raise Ea::Cli::Error, "Failed to validate #{path}: #{e.message}"
        end
      end
    end
  end
end
