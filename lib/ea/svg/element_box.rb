# frozen_string_literal: true

require "ostruct"

module Ea
  module Svg
    # Renders one DiagramElement as an SVG <g> containing the rect
    # and a name label. Class-shape rendering (with attribute /
    # operation compartments) is future work; for now we emit a
    # simple labeled box that mirrors EA's logical placement.
    class ElementBox
      attr_reader :element, :model_index

      def initialize(element, model_index:)
        @element = element
        @model_index = model_index
      end

      def render
        return "" unless element.bounds

        b = normalize_bounds(element.bounds)
        style = StyleResolver.new(element.style)
        label_text = model_element_name

        <<~SVG.chomp
          <g class="element" data-element-id="#{escape(element.id)}">
            <rect x="#{b.x}" y="#{b.y}" width="#{b.width}" height="#{b.height}"
                  fill="#{style.fill_color}" stroke="#{style.stroke_color}"
                  stroke-width="#{style.stroke_width}"/>
            <text x="#{b.x + (b.width / 2.0)}"
                  y="#{b.y + (b.height / 2.0)}"
                  text-anchor="middle" dominant-baseline="middle"
                  fill="#{style.font_color}"
                  font-family="sans-serif" font-size="14">#{escape(label_text)}</text>
          </g>
        SVG
      end

      private

      def model_element_name
        ref = element.model_element_ref
        return "(unbound)" unless ref

        model = model_index[ref]
        model&.name || "(missing #{ref})"
      end

      def normalize_bounds(bounds)
        x = bounds.x
        y = bounds.y
        w = bounds.width
        h = bounds.height
        x, w = x + w, -w if w.negative?
        y, h = y + h, -h if h.negative?
        OpenStruct.new(x: x, y: y, width: w, height: h)
      end

      def escape(text)
        return "" if text.nil?

        text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub("\"", "&quot;")
      end
    end
  end
end
