# frozen_string_literal: true

require "json"

module Ea
  module Cli
    module Command
      # `ea export SUB FILE` where SUB ∈ {xmi, json, plantuml, xsd}.
      #
      # Routes to the appropriate Exporter based on `sub`. Each
      # exporter lives under Ea::Export::* and implements
      # `call(model, **opts) → String`. Adding a new format = adding
      # a new exporter (OCP), no changes to this command.
      class Export < Base
        COLUMNS = %i[format bytes_written path].freeze

        def call
          validate_file!(file_path)
          output = exporter.call(model, **exporter_options)
          path = write_output(output, default_name: default_name)
          formatter.render([[sub, output.bytesize, path]], columns: COLUMNS)
        end

        private

        def sub
          options[:sub].to_sym
        end

        def exporter
          @exporter ||= EXPORTERS.fetch(sub) do
            raise Ea::Cli::Error,
                  "Unknown export format: #{sub}. " \
                  "Valid: #{EXPORTERS.keys.join(", ")}"
          end
        end

        # Each value is a callable taking (model, **opts) and returning
        # a string. New formats add a new entry here without touching
        # this class body. Lambdas lazy-resolve autoloaded namespaces.
        EXPORTERS = {
          xmi: ->(model, **o) { Ea::Export::Xmi::Generator.call(model, **o) },
          json: ->(model, **o) { Ea::Export::Json::Generator.call(model, **o) },
          "json-schema": ->(model, **o) { Ea::Export::JsonSchema::Generator.call(model, **o) },
          plantuml: ->(model, **o) { Ea::Export::PlantUml::Generator.call(model, **o) },
          xsd: ->(model, **o) { Ea::Export::Xsd::Generator.call(model, **o) }
        }.freeze

        def exporter_options
          opts = {}
          opts[:target_namespace] = options[:target_namespace] if options[:target_namespace]
          opts[:prefix] = options[:prefix] if options[:prefix]
          opts
        end

        def model
          @model ||= load_database(file_path)
        end

        def default_name
          base = File.basename(file_path, ".*")
          dir = File.dirname(file_path)
          ext = exporter_extension
          File.join(dir, "#{base}.#{ext}")
        end

        def exporter_extension
          case sub
          when :xmi then "xmi"
          when :json then "json"
          when :"json-schema" then "schema.json"
          when :plantuml then "puml"
          when :xsd then "xsd"
          else sub.to_s
          end
        end
      end
    end
  end
end
