# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea parse FILE [--format json|yaml]`
      #
      # Parses the EA file (QEA or Sparx XMI) to a Lutaml::Uml::Document and
      # serializes it. Requires lutaml-uml.
      class Parse < Base
        def call
          document = parse_to_uml(file_path)
          formatter_output(document)
        end

        private

        def formatter_output(document)
          case (options[:format] || :yaml).to_sym
          when :json then puts document.to_json
          when :yaml then puts document.to_yaml
          else
            raise Ea::Cli::Error, "Unknown format: #{options[:format]}"
          end
        end
      end
    end
  end
end
