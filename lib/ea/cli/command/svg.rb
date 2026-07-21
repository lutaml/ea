# frozen_string_literal: true

require "fileutils"

module Ea
  module Cli
    module Command
      # `ea svg NAME FILE [--output=PATH] [--mode=ea|thin]`
      # `ea svg --all FILE [--output-dir=PATH] [--mode=ea|thin]`
      #
      # Renders one (NAME) or every (--all) diagram from a QEA or
      # XMI file into standalone SVG using the umldi content
      # (placed element bounds + connector waypoints) captured in
      # Ea::Model::Diagram.
      #
      # Default emitter is EaEmitter::Document which mirrors EA's SVG
      # structure (DOCTYPE, layered groups, EA-style markers). Pass
      # --mode=thin for the simpler Renderer output.
      class Svg < Base
        def call
          return render_all if options[:all]

          render_one
        end

        private

        def render_one
          diagram = find_diagram
          svg = emitter_for_mode.new(diagram,
                                       model_index: document.index_by_id).render

          output_path = resolve_output_path(diagram)
          FileUtils.mkdir_p(File.dirname(output_path))
          File.write(output_path, svg)

          formatter.render([[output_path]], columns: [:written_to])
        end

        def render_all
          out_dir = options[:output_dir] || default_output_dir
          FileUtils.mkdir_p(out_dir)
          paths = document.diagrams.map do |diagram|
            svg = emitter_for_mode.new(diagram,
                                         model_index: document.index_by_id).render
            path = File.join(out_dir, "#{diagram.id}.svg")
            File.write(path, svg)
            path
          end

          formatter.render(paths.map { |p| [p] }, columns: [:written_to])
        end

        def default_output_dir
          base = File.basename(file_path, ".*")
          dir = File.dirname(file_path)
          File.join(dir, "#{base}.svgs")
        end

        def emitter_for_mode
          case (options[:mode] || :ea).to_sym
          when :ea
            Ea::Svg::EaEmitter::Document
          when :thin
            Ea::Svg::Renderer
          else
            raise Ea::Cli::UnsupportedFormat,
                  "Unknown svg mode: #{options[:mode]}"
          end
        end

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
