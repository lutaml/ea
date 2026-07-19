# frozen_string_literal: true

require "fileutils"

module Ea
  module Cli
    module Command
      # `ea svg NAME FILE [--output=PATH]`
      #
      # Renders a single diagram from a QEA or XMI file into a
      # standalone SVG using the umldi content (placed element
      # bounds + connector waypoints) captured in Ea::Model::Diagram.
      class Svg < Base
        def call
          diagram = find_diagram
          svg = Ea::Svg::Renderer.new(diagram,
                                       model_index: document.index_by_id).render

          output_path = resolve_output_path(diagram)
          FileUtils.mkdir_p(File.dirname(output_path))
          File.write(output_path, svg)

          formatter.render([[output_path]], columns: [:written_to])
        end

        private

        def document
          @document ||= build_model_document
        end

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

        def diagram_name
          options[:name] or raise Ea::Cli::Error, "missing required diagram name"
        end

        def find_diagram
          match = document.diagrams.find { |d| d.name == diagram_name }
          return match if match

          raise Ea::Cli::Error,
                "Diagram #{diagram_name.inspect} not found in #{file_path}. " \
                "Use `ea diagrams list #{file_path}` to see names."
        end

        def resolve_output_path(diagram)
          options[:output] || begin
            base = File.basename(file_path, ".*")
            dir = File.dirname(file_path)
            safe_name = (diagram.name || "diagram").gsub(/[^\w.\-]+/, "_")
            File.join(dir, "#{base}.#{safe_name}.svg")
          end
        end
      end
    end
  end
end
