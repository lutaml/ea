# frozen_string_literal: true

# frozen_string: true

require "fileutils"

module Ea
  module Cli
    module Command
      # `ea render NAME FILE [--format=svg|png|pdf]`
      # `ea render --all FILE [--output-dir=PATH]`
      #
      # Unified rendering command. Currently supports SVG; PNG and PDF
      # are routed through SVG intermediate (planned: rsvg-convert /
      # headless chrome). The original `ea svg` command is preserved
      # as a backward-compatible alias.
      class Render < Base
        def call
          return render_all if options[:all]

          render_one
        end

        private

        def render_one
          diagram = find_diagram
          write_diagram(diagram, resolve_output_path(diagram))
        end

        def render_all
          out_dir = options[:output_dir] || default_output_dir
          FileUtils.mkdir_p(out_dir)
          paths = document.diagrams.map do |diagram|
            path = File.join(out_dir, "#{diagram.id}.#{format_ext}")
            write_diagram(diagram, path)
            path
          end
          formatter.render(paths.map { |p| [p] }, columns: [:written_to])
        end

        def write_diagram(diagram, output_path)
          FileUtils.mkdir_p(File.dirname(output_path))
          svg = render_svg(diagram)

          case requested_format
          when :svg
            File.write(output_path, svg)
          when :png
            File.binwrite(output_path, svg_to_png(svg))
          when :pdf
            File.binwrite(output_path, svg_to_pdf(svg))
          else
            raise Ea::Cli::Error, "Unknown format: #{requested_format.inspect}"
          end
        end

        def render_svg(diagram)
          emitter_for_mode.new(diagram,
                               model_index: document.index_by_id,
                               document: document).render
        end

        def svg_to_png(svg)
          Ea::Render::ImageConverter
            .new(svg).to_png
        end

        def svg_to_pdf(svg)
          Ea::Render::ImageConverter
            .new(svg).to_pdf
        end

        def requested_format
          (options[:format] || :svg).to_sym
        end

        def format_ext
          case requested_format
          when :svg then "svg"
          when :png then "png"
          when :pdf then "pdf"
          else "svg"
          end
        end

        def default_output_dir
          base = File.basename(file_path, ".*")
          dir = File.dirname(file_path)
          File.join(dir, "#{base}.renders")
        end

        def emitter_for_mode
          Ea::Svg::EaEmitter::Document
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
            File.join(dir, "#{base}.#{safe_name}.#{format_ext}")
          end
        end
      end
    end
  end
end
