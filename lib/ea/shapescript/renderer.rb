# frozen_string_literal: true

module Ea
  module Shapescript
    # Renders a list of parsed Shape primitives to SVG elements as
    # a single string. Coordinates are emitted as-is — callers
    # should wrap in a `<g>` with the appropriate transform if they
    # want to position the icon.
    module Renderer
      module_function

      # @param shapes [Array<Shape>]
      # @param fill [String] SVG fill color
      # @param stroke [String] SVG stroke color
      # @return [String] SVG fragment with one element per shape
      def render(shapes, fill: "#FFFFFF", stroke: "#000000")
        return "" if shapes.nil? || shapes.empty?

        shapes.map { |s| render_one(s, fill: fill, stroke: stroke) }.join("\n")
      end

      def render_one(shape, fill:, stroke:)
        case shape.kind
        when :rectangle then render_rect(shape.params, fill, stroke)
        when :ellipse then render_ellipse(shape.params, fill, stroke)
        when :polygon then render_polygon(shape.params, fill, stroke)
        when :line then render_line(shape.params, stroke)
        when :path then render_path(shape.params, stroke)
        when :label then render_label(shape.params, fill)
        end
      end

      def render_label(p, fill)
        text = p.first.to_s
        %(<text x="0" y="0" fill="#{fill}">#{escape(text)}</text>)
      end

      def escape(text)
        XmlEscape.call(text)
      end

      def render_rect(p, fill, stroke)
        x, y, w, h = p
        %(<rect x="#{x}" y="#{y}" width="#{w}" height="#{h}" fill="#{fill}" stroke="#{stroke}"/>)
      end

      def render_ellipse(p, fill, stroke)
        cx, cy, rx, ry = p
        %(<ellipse cx="#{cx}" cy="#{cy}" rx="#{rx}" ry="#{ry}" fill="#{fill}" stroke="#{stroke}"/>)
      end

      def render_polygon(p, fill, stroke)
        points = p.each_slice(2).map { |x, y| "#{x},#{y}" }.join(" ")
        %(<polygon points="#{points}" fill="#{fill}" stroke="#{stroke}"/>)
      end

      def render_line(p, stroke)
        x1, y1, x2, y2 = p
        %(<line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="#{stroke}"/>)
      end

      def render_path(p, stroke)
        return "" if p.empty?

        x, y = p.shift(2)
        d = "M #{x} #{y}"
        p.each_slice(2) { |px, py| d += " L #{px} #{py}" }
        %(<path d="#{d}" fill="none" stroke="#{stroke}"/>)
      end
    end
  end
end
