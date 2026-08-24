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
          xmi: ->(model, **o) { Ea::Transformers.qea_to_xmi(model, mdg_registry: o[:mdg_registry]) },
          json: ->(model, **o) { Ea::Export::Json::Generator.call(model, **o) },
          "json-schema": ->(model, **o) { Ea::Export::JsonSchema::Generator.call(model, **o) },
          plantuml: ->(model, **o) { Ea::Export::PlantUml::Generator.call(model, **o) },
          xsd: ->(model, **o) { Ea::Export::Xsd::Generator.call(model, **Ea::Cli::Command::Export.xsd_options(o)) }
        }.freeze

        # Load GMLClassMapping + GMLNamespaces fixtures when present
        # (repo-local dev path) and pass to the XSD generator. Keeps
        # fixture-path knowledge in the CLI layer; lib stays pure.
        def self.xsd_options(opts)
          mapping = load_if_present("spec/fixtures/mdg/ea_config/gml/GMLClassMapping.xml",
                                    Ea::Export::Xsd::ClassMapping)
          namespaces = load_if_present("spec/fixtures/mdg/ea_config/gml/GMLNamespaces.xml",
                                        Ea::Export::Xsd::NamespaceRegistry)
          opts[:class_mapping] = mapping if mapping
          opts[:namespaces] = namespaces if namespaces
          opts
        end

        def self.load_if_present(path, loader)
          return nil unless File.exist?(path)

          loader.from_path(path)
        rescue StandardError
          nil
        end

        def exporter_options
          opts = {}
          opts[:target_namespace] = options[:target_namespace] if options[:target_namespace]
          opts[:prefix] = options[:prefix] if options[:prefix]
          add_mdg_registry(opts)
          opts
        end

        # Registry construction is xmi-only: the other exporters reject
        # unknown keywords.
        def add_mdg_registry(opts)
          return unless options[:mdg] && sub == :xmi

          opts[:mdg_registry] = Ea::Mdg::Registry.from_paths(options[:mdg])
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
