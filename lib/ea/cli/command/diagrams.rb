# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea diagrams ACTION FILE [NAME]`
      #
      # Actions:
      #   list FILE           — list diagrams in a QEA/XMI file (standalone)
      #   extract FILE NAME   — render the named diagram from a LUR file to SVG
      #
      # `list` reads the EA database directly (no lutaml-uml required).
      # `extract` delegates to {Ea::Diagram::Extractor}, which requires a
      # `.lur` (Lutaml UML Repository) file. To render diagrams from a QEA,
      # first convert it to `.lur` via the `lutaml` gem.
      class Diagrams < Base
        ACTIONS = %w[list extract].freeze
        LUR_EXT = ".lur"

        def call
          case action
          when "list"    then list
          when "extract" then extract
          else
            raise Ea::Cli::UnknownAction.new(action, valid: ACTIONS)
          end
        end

        private

        def action
          options[:action] or raise Ea::Cli::Error, "missing required ACTION"
        end

        def name
          options[:name] or raise Ea::Cli::Error, "missing required NAME"
        end

        def list
          db = load_database
          rows = db.diagrams.map { |d| [d.name, diagram_type_label(d), d.ea_guid] }
          formatter.render(rows, columns: %i[name type guid])
        end

        def extract
          validate_lur!(file_path)
          result = extractor.extract_one(file_path, name, extract_options)
          raise Ea::Cli::Error, result[:message] unless result[:success]

          path = result[:path] || write_output(result.fetch(:svg_content),
                                                default_name: "#{name}.svg")
          formatter.render([[path]], columns: [:written_to])
        end

        def extractor
          Ea::Diagram::Extractor.new
        end

        def extract_options
          opts = {}
          opts[:output] = options[:output] if options[:output]
          opts
        end

        def validate_lur!(path)
          return if path.end_with?(LUR_EXT)

          raise Ea::Cli::UnsupportedFormat.new(
            path,
            "diagrams extract requires a #{LUR_EXT} file; " \
            "convert from QEA via the lutaml gem first",
          )
        end

        def diagram_type_label(diagram)
          diagram.diagram_type || "Logical"
        end
      end
    end
  end
end
