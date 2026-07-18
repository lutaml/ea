# frozen_string_literal: true

require "thor"

module Ea
  module Cli
    class App < Thor
      # Shared kwargs for any command that writes to a file. Keeping
      # the short-form alias in one place makes the CLI surface
      # consistent and the convention a single source of truth:
      # changing `-o` everywhere is a one-line edit, not a per-command
      # search, and every output-bearing command honours the same flag.
      OUTPUT_OPTION = { type: :string, aliases: :o }.freeze

      class << self
        def exit_on_failure?
          true
        end
      end

      desc "version", "Show ea gem version"
      def version
        puts Ea::VERSION
      end

      desc "list FILE", "List model elements (auto-detects QEA or XMI)"
      option :type, type: :string,
                    desc: "Filter: class | interface | package | diagram | connector | enum"
      option :format, type: :string, default: "table",
                      desc: "Output format: table | json | yaml"
      def list(file)
        Command::List.new(file: file, **symbolize(options)).call
      end

      desc "diagrams ACTION FILE [NAME]",
           "Diagram operations: list FILE | extract NAME FILE"
      option :format, type: :string, default: "table"
      option :output, **OUTPUT_OPTION, desc: "Output path (extract only)"
      def diagrams(action, file = nil, name = nil)
        Command::Diagrams
          .new(action: action, file: file, name: name, **symbolize(options))
          .call
      end

      desc "validate FILE", "Validate EA model"
      option :format, type: :string, default: "table"
      def validate(file)
        Command::Validate.new(file: file, **symbolize(options)).call
      end

      desc "stats FILE", "Show collection counts (standalone — no lutaml-uml)"
      option :format, type: :string, default: "table"
      def stats(file)
        Command::Stats.new(file: file, **symbolize(options)).call
      end

      desc "parse FILE", "Parse to Lutaml::Uml::Document (requires lutaml-uml)"
      option :format, type: :string, default: "yaml",
                      desc: "Output: json | yaml"
      def parse(file)
        Command::Parse.new(file: file, **symbolize(options)).call
      end

      desc "convert FILE", "Convert between EA formats (e.g. QEA → XMI)"
      option :to, type: :string, required: true, desc: "Target format: xmi"
      option :output, **OUTPUT_OPTION, desc: "Output path"
      option :format, type: :string, default: "table"
      def convert(file)
        Command::Convert.new(file: file, **symbolize(options)).call
      end

      desc "spa FILE", "Generate single-page app (SPA) from QEA/XMI/LUR"
      option :output, **OUTPUT_OPTION,
             desc: "Output path (default: <basename>.html)"
      option :mode, type: :string, default: "single_file",
                    desc: "Output mode: single_file | multi_file"
      def spa(file)
        Command::Spa.new(file: file, **symbolize(options)).call
      end

      private

      def symbolize(opts)
        opts.transform_keys(&:to_sym)
      end
    end
  end
end
