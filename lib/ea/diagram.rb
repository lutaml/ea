# frozen_string_literal: true

module Ea
  module Diagram
    autoload :SvgRenderer, "ea/diagram/svg_renderer"
    autoload :LayoutEngine, "ea/diagram/layout_engine"
    autoload :StyleParser, "ea/diagram/style_parser"
    autoload :PathBuilder, "ea/diagram/path_builder"
    autoload :StyleResolver, "ea/diagram/style_resolver"
    autoload :Configuration, "ea/diagram/configuration"
    autoload :Util, "ea/diagram/util"
    autoload :Extractor, "ea/diagram/extractor"
    autoload :ElementRenderers, "ea/diagram/element_renderers"

    class DiagramRenderer
      attr_reader :diagram_data, :layout_engine, :style_parser

      def initialize(diagram_data)
        @diagram_data = diagram_data
        @layout_engine = LayoutEngine.new
        @style_parser = StyleParser.new
      end

      def render_svg(options = {})
        svg_renderer = SvgRenderer.new(self, options)
        svg_renderer.render
      end

      def bounds
        layout_engine.calculate_bounds(diagram_data)
      end

      def elements
        diagram_data[:elements] || []
      end

      def connectors
        diagram_data[:connectors] || []
      end
    end

    def self.render(diagram_data, options = {})
      renderer = DiagramRenderer.new(diagram_data)
      renderer.render_svg(options)
    end
  end
end
