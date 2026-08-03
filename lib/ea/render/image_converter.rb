# frozen_string_literal: true

module Ea
  module Render
    # Converts SVG strings to PNG and PDF using available system
    # tools. Detects `rsvg-convert`, ImageMagick `convert`, and
    # headless Chrome (`chromium --headless`). Raises a clear error
    # when no converter is available.
    class ImageConverter
      attr_reader :svg

      # @param svg [String] SVG markup
      def initialize(svg)
        @svg = svg
      end

      # @return [String] PNG bytes
      def to_png
        with_tempfile(".svg") do |svg_path|
          File.write(svg_path, svg)
          convert(svg_path, :png)
        end
      end

      # @return [String] PDF bytes
      def to_pdf
        with_tempfile(".svg") do |svg_path|
          File.write(svg_path, svg)
          convert(svg_path, :pdf)
        end
      end

      # Returns the first available converter executable, or nil.
      # @return [Symbol, nil] :rsvg_convert | :magick | :chrome
      def self.available_converter
        return :rsvg_convert if system("which rsvg-convert > /dev/null 2>&1")
        return :magick if system("which convert > /dev/null 2>&1")
        return :chrome if chromium_executable

        nil
      end

      def self.chromium_executable
        %w[chromium chromium-browser google-chrome
           /Applications/Chromium.app/Contents/MacOS/Chromium
           /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome]
          .find { |exe| File.executable?(exe) || system("which #{exe} > /dev/null 2>&1") }
      end

      private

      def convert(svg_path, target)
        converter = self.class.available_converter
        raise Ea::Cli::Error,
              "No SVG→#{target.upcase} converter available. " \
              "Install rsvg-convert (librsvg) or ImageMagick." unless converter

        with_tempfile(".#{target}") do |out_path|
          run_converter(converter, svg_path, out_path, target)
          File.binread(out_path)
        end
      end

      def run_converter(name, svg_path, out_path, target)
        case name
        when :rsvg_convert
          format_flag = target == :pdf ? "-f pdf" : "-f png"
          system("rsvg-convert #{format_flag} -o #{shell_quote(out_path)} " \
                 "#{shell_quote(svg_path)}",
                 exception: true)
        when :magick
          system("convert #{shell_quote(svg_path)} #{shell_quote(out_path)}",
                 exception: true)
        when :chrome
          chrome = self.class.chromium_executable
          system("#{shell_quote(chrome)} --headless --disable-gpu " \
                 "--print-to-pdf=#{shell_quote(out_path)} " \
                 "file://#{svg_path}",
                 exception: true)
        end
      end

      # Quote a path for safe inclusion in a shell command. Only
      # handles paths without single quotes (sufficient for tempfile
      # paths which are numeric IDs under /tmp).
      def shell_quote(path)
        "'#{path}'"
      end

      def with_tempfile(suffix)
        require "tmpdir"
        Dir.mktmpdir("ea-render-") do |dir|
          path = File.join(dir, "input#{suffix}")
          yield path
        ensure
          File.delete(path) if File.exist?(path)
        end
      end
    end
  end
end
