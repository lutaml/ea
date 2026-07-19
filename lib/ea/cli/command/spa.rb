# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea spa FILE [--output=PATH] [--mode=MODE]`
      #
      # Generates a static single-page application (SPA) from a QEA
      # or XMI file using the Ea::Model native pipeline:
      #
      #   1. Source parse (Ea::Qea::Database / Xmi::Sparx::Root)
      #   2. Source adapter → Ea::Model::Document
      #   3. Ea::Spa::Projector → skeleton + shards + search index
      #   4. Ea::Spa::Output::Strategy → HTML/JSON on disk
      class Spa < Base
        DEFAULT_MODE = :single_file

        def call
          document = build_model_document
          output_path = resolve_output_path
          Ea::Spa::Generator.new(
            document,
            output: output_path,
            mode: mode,
            configuration: spa_configuration
          ).generate

          formatter.render([[output_path]], columns: [:written_to])
        end

        private

        def build_model_document
          case File.extname(file_path).downcase
          when ".qea"
            Ea::Sources::Qea::Adapter.from_path(file_path)
          when ".xmi"
            Ea::Sources::Xmi::Adapter.from_path(file_path)
          else
            raise Ea::Cli::UnsupportedFormat,
                  "Unknown file format: #{File.extname(file_path)}"
          end
        end

        def mode
          (options[:mode] || DEFAULT_MODE).to_sym
        end

        def spa_configuration
          path = options[:config]
          return nil unless path

          expanded = File.expand_path(path)
          unless File.exist?(expanded)
            raise Ea::Cli::FileNotFound,
                  "SPA config not found: #{path}"
          end

          Ea::Spa::Configuration.load(expanded)
        end

        def resolve_output_path
          options[:output] || default_output_path
        end

        def default_output_path
          base = File.basename(file_path, ".*")
          dir = File.dirname(file_path)
          if mode == :sharded
            File.join(dir, "#{base}.spa")
          else
            File.join(dir, "#{base}.html")
          end
        end
      end
    end
  end
end
