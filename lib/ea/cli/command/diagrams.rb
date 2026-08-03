# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea diagrams ACTION FILE [NAME]`
      #
      # Actions:
      #   list FILE           — list diagrams in a QEA/XMI file
      #   extract FILE NAME   — render the named diagram to SVG
      #
      # Both actions use the modern Ea::Model pipeline (parsed via
      # Ea::Sources::Qea/Xmi::Adapter, rendered via
      # Ea::Svg::EaEmitter::Document). No lutaml-uml dependency.
      class Diagrams < Base
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
          rows = document.diagrams.map do |d|
            [d.name, diagram_type_label(d)]
          end
          formatter.render(rows, columns: %i[name type])
        end

        def extract
          diagram = document.diagrams.find { |d| d.name == name }
          unless diagram
            raise Ea::Cli::Error,
                  "Diagram #{name.inspect} not found in #{file_path}. " \
                  "Use `ea diagrams list #{file_path}` to see names."
          end

          svg = Ea::Svg::EaEmitter::Document.new(diagram,
                                                   model_index: document.index_by_id,
                                                   document: document).render
          path = options[:output] || begin
            base = File.basename(file_path, ".*")
            dir = File.dirname(file_path)
            safe_name = (diagram.name || "diagram").gsub(/[^\w.\-]+/, "_")
            File.join(dir, "#{base}.#{safe_name}.svg")
          end
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, svg)
          formatter.render([[path]], columns: [:written_to])
        end

        def diagram_type_label(diagram)
          diagram.diagram_type || "Logical"
        end

        def document
          @document ||= case File.extname(file_path).downcase
                        when ".qea"
                          Ea::Sources::Qea::Adapter.from_path(file_path)
                        when ".xmi", ".xml"
                          Ea::Sources::Xmi::Adapter.from_path(file_path)
                        else
                          raise Ea::Cli::UnsupportedFormat,
                                "Unknown file format: #{File.extname(file_path)}"
                        end
        end
      end
    end
  end
end
