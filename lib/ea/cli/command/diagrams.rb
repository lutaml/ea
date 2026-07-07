# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea diagrams ACTION FILE [NAME]`
      #
      # Actions:
      #   list FILE           — list diagrams in a QEA/XMI/LUR file (standalone)
      #   extract FILE NAME   — render the named diagram to SVG
      #
      # `list` reads the EA database directly (no lutaml-uml required
      # for QEA; XMI parsing via xmi gem only).
      #
      # `extract` accepts QEA, XMI, or LUR. The Repository is built
      # from the input file via `RepositoryBuilder` (single source of
      # truth — QEA/XMI are parsed via `Ea::Transformations`, LUR is
      # loaded natively via `Repository.from_file`).
      class Diagrams < Base
        include RepositoryBuilder

        ACTIONS = %w[list extract].freeze

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
          repository = RepositoryBuilder.build_repository(file_path)
          result = extractor.extract_one(repository, name, extract_options)
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

        def diagram_type_label(diagram)
          diagram.diagram_type || "Logical"
        end
      end
    end
  end
end
