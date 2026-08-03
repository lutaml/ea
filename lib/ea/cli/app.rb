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

      # Shared kwargs for any command that accepts a YAML config file.
      # Matches OUTPUT_OPTION; adding config support to a command is a
      # one-line addition.
      CONFIG_OPTION = { type: :string, aliases: :c }.freeze

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

      desc "spa FILE", "Generate single-page app (SPA) from QEA/XMI"
      option :output, **OUTPUT_OPTION,
             desc: "Output path (default: <basename>.html or <basename>.spa/)"
      option :config, **CONFIG_OPTION,
             desc: "Path to SPA YAML config (overrides model metadata: title, description, etc.)"
      option :mode, type: :string, default: "single_file",
                    desc: "Output mode: single_file | sharded"
      def spa(file)
        Command::Spa.new(file: file, **symbolize(options)).call
      end

      desc "svg NAME FILE", "Render a diagram from QEA/XMI to standalone SVG"
      option :output, **OUTPUT_OPTION,
             desc: "Output path (default: <basename>.<diagram>.svg)"
      option :all, type: :boolean, default: false,
                   desc: "Render every diagram in the source file (NAME ignored)"
      option :output_dir, type: :string,
                          desc: "Directory for --all output (default: <basename>.svgs/)"
      def svg(name = nil, file = nil)
        Command::Svg.new(name: name, file: file, **symbolize(options)).call
      end

      desc "diff OLD NEW", "Compare two QEA files structurally"
      option :format, type: :string, default: "table",
                      desc: "Output format: table | json | html"
      option :output, **OUTPUT_OPTION, desc: "Output path (html format)"
      def diff(old, new)
        Command::Diff.new(old: old, new: new, **symbolize(options)).call
      end

      desc "render NAME FILE", "Render diagram(s) to SVG/PNG/PDF"
      option :output, **OUTPUT_OPTION,
             desc: "Output path (default: <basename>.<diagram>.<ext>)"
      option :all, type: :boolean, default: false,
                   desc: "Render every diagram in the source file (NAME ignored)"
      option :format, type: :string, default: "svg",
                      desc: "Output format: svg | png | pdf"
      option :output_dir, type: :string,
                          desc: "Directory for --all output (default: <basename>.renders/)"
      def render(name = nil, file = nil)
        Command::Render.new(name: name, file: file, **symbolize(options)).call
      end

      desc "export SUB FILE", "Export model (SUB: xmi|json|plantuml|xsd)"
      option :output, **OUTPUT_OPTION, desc: "Output path"
      option :package, type: :string, desc: "Restrict to a package name"
      def export(sub, file)
        Command::Export.new(sub: sub, file: file, **symbolize(options)).call
      end

      desc "mdg ACTION [ARG]", "MDG technologies: list | show NAME"
      option :format, type: :string, default: "table"
      def mdg(action, arg = nil)
        Command::Mdg.new(action: action, arg: arg, **symbolize(options)).call
      end

      desc "lint FILE", "Run model quality lint rules"
      option :rule, type: :string, desc: "Filter by rule name substring"
      option :severity, type: :string, desc: "Filter: error | warning | info"
      option :format, type: :string, default: "table"
      def lint(file)
        Command::Lint.new(file: file, **symbolize(options)).call
      end

      desc "query FILE", "Filter model elements by criteria"
      option :type, type: :string, desc: "Filter by object_type (Class, etc.)"
      option :package, type: :string, desc: "Restrict to a package name"
      option :stereotype, type: :string, desc: "Filter by stereotype name"
      option :format, type: :string, default: "table"
      def query(file)
        Command::Query.new(file: file, **symbolize(options)).call
      end

      desc "info NAME FILE", "Show details of a single element"
      option :format, type: :string, default: "table"
      def info(name, file)
        Command::Info.new(name: name, file: file, **symbolize(options)).call
      end

      private

      def symbolize(opts)
        opts.transform_keys(&:to_sym)
      end
    end
  end
end
