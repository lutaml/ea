# frozen_string_literal: true

require "ostruct"

module Ea
  module Svg
    # Renders one DiagramElement as a 3-compartment UML class box,
    # matching EA's drawing convention:
    #
    #   ┌─────────────────────────┐
    #   │ «Stereotype»            │  ← header (stereotype + name)
    #   │ qualified::Name         │
    #   ├─────────────────────────┤
    #   │ + attr1: Type [0..1]    │  ← attributes
    #   │ + attr2: Type [0..*]    │
    #   ├─────────────────────────┤
    #   │ + op1(arg: T): T        │  ← operations
    #   └─────────────────────────┘
    #
    # The stored element bounds are honored as the outer rectangle;
    # internal layout (header / attrs / ops heights) is computed
    # proportionally based on line count.
    class ElementBox
      HEADER_LINE_HEIGHT = 17
      ATTR_LINE_HEIGHT   = 17
      OP_LINE_HEIGHT     = 17
      TOP_PADDING        = 17

      STEREOTYPE_COLORS = {
        "featuretype" => "#FFFFCC", # yellow
        "feature"     => "#FFFFCC",
        "type"        => "#CCFFCC", # green
        "datatype"    => "#FFCCFF", # pink
        "basictype"   => "#FFCCFF",
        "codelist"    => "#FFCCFF",
        "enumeration" => "#FFCCFF",
        "union"       => "#F0E68C", # khaki
        "adeelement"  => "#F5F5DC"  # beige
      }.freeze
      DEFAULT_FILL = "#FFFFFF"

      attr_reader :element, :model_index

      def initialize(element, model_index:)
        @element = element
        @model_index = model_index
      end

      def render
        return "" unless element.bounds

        b = normalize_bounds(element.bounds)
        classifier = bound_classifier
        return render_simple_box(b) unless classifier

        render_class_box(b, classifier)
      end

      private

      def bound_classifier
        ref = element.model_element_ref
        return nil unless ref

        candidate = model_index[ref]
        return nil unless candidate.is_a?(Ea::Model::Classifier)

        candidate
      end

      def render_simple_box(bounds)
        style = StyleResolver.new(element.style)
        <<~SVG.chomp
          <g class="element" data-element-id="#{escape(element.id)}">
            <rect x="#{bounds.x}" y="#{bounds.y}" width="#{bounds.width}" height="#{bounds.height}"
                  fill="#{fill_color(style)}" stroke="#{style.stroke_color}"
                  stroke-width="#{style.stroke_width}"/>
            <text x="#{bounds.x + (bounds.width / 2.0)}"
                  y="#{bounds.y + (bounds.height / 2.0)}"
                  text-anchor="middle" dominant-baseline="middle"
                  fill="#{style.font_color}"
                  font-family="sans-serif" font-size="14">#{escape(element.id)}</text>
          </g>
        SVG
      end

      def render_class_box(bounds, classifier)
        stereotype = primary_stereotype(classifier)
        fill = STEREOTYPE_COLORS[stereotype&.downcase] || DEFAULT_FILL
        style = StyleResolver.new(element.style)
        stroke = style.stroke_color
        stroke_width = style.stroke_width
        font_color = style.font_color

        header_lines = build_header_lines(classifier, stereotype)
        attr_lines = build_attribute_lines(classifier)
        op_lines = build_operation_lines(classifier)

        header_bottom = bounds.y + header_height(header_lines.size)
        attrs_bottom = header_bottom + compartment_height(attr_lines.size)
        ops_bottom = attrs_bottom + compartment_height(op_lines.size)

        parts = []
        parts << %(<g class="element" data-element-id="#{escape(element.id)}">)
        parts << render_outer_rect(bounds, fill, stroke, stroke_width)
        parts << render_header_divider(bounds, header_bottom, stroke, stroke_width)
        parts << render_attrs_divider(bounds, attrs_bottom, stroke, stroke_width) if op_lines.any?
        parts << render_header_text(bounds, header_lines, font_color)
        parts << render_attribute_text(bounds, header_bottom, attr_lines, font_color)
        parts << render_operation_text(bounds, attrs_bottom, op_lines, font_color)
        parts << %(</g>)
        parts.join("\n            ")
      end

      def build_header_lines(classifier, stereotype)
        lines = []
        lines << "«#{stereotype}»" if stereotype && !stereotype.empty?
        lines << (classifier.qualified_name&.split("::")&.last || classifier.name || "(unnamed)")
        lines
      end

      def build_attribute_lines(classifier)
        return [] unless classifier.properties

        classifier.properties.map do |prop|
          vis = visibility_marker(prop.visibility)
          mult = multiplicity_text(prop)
          type = prop.type_name ? ": #{prop.type_name}" : ""
          "#{vis} #{prop.name}#{type}#{mult}"
        end
      end

      def build_operation_lines(classifier)
        return [] unless classifier.operations

        classifier.operations.map do |op|
          vis = visibility_marker(op.visibility)
          ret = op.return_type_name ? ": #{op.return_type_name}" : ""
          params = (op.parameters || []).map { |p| "#{p.name}: #{p.type_name || 'T'}" }.join(", ")
          "#{vis} #{op.name}(#{params})#{ret}"
        end
      end

      def visibility_marker(visibility)
        case visibility&.downcase
        when "public" then "+"
        when "private" then "-"
        when "protected" then "#"
        when "package" then "~"
        else "+"
        end
      end

      def multiplicity_text(prop)
        lower = prop.multiplicity_lower
        upper = prop.multiplicity_upper
        return "" if lower.nil? && upper.nil?
        return "" if lower == 1 && upper == 1

        upper_text = upper == -1 ? "*" : upper
        lower_text = lower || 0
        return "[0..*]" if lower_text == 0 && upper == -1
        return "[#{lower_text}]" if lower_text == upper

        "[#{lower_text}..#{upper_text}]"
      end

      def primary_stereotype(classifier)
        refs = classifier.stereotype_refs
        return nil if refs.nil? || refs.empty?

        refs.first.to_s.split("::").last
      end

      def fill_color(style)
        stereotype = primary_stereotype_from_style
        STEREOTYPE_COLORS[stereotype&.downcase] || style.fill_color
      end

      def primary_stereotype_from_style
        nil
      end

      def header_height(line_count)
        TOP_PADDING + (line_count * HEADER_LINE_HEIGHT)
      end

      def compartment_height(line_count)
        return 0 if line_count.zero?

        10 + (line_count * (line_count == 0 ? 0 : (line_count < 3 ? 17 : 17)))
      end

      def render_outer_rect(bounds, fill, stroke, stroke_width)
        %(  <rect x="#{bounds.x}" y="#{bounds.y}" width="#{bounds.width}" height="#{bounds.height}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{stroke_width}"/>)
      end

      def render_header_divider(bounds, y, stroke, stroke_width)
        %(  <path d="M #{bounds.x} #{y} L #{bounds.x + bounds.width} #{y}" stroke="#{stroke}" stroke-width="#{stroke_width}" fill="none"/>)
      end

      def render_attrs_divider(bounds, y, stroke, stroke_width)
        %(  <path d="M #{bounds.x} #{y} L #{bounds.x + bounds.width} #{y}" stroke="#{stroke}" stroke-width="#{stroke_width}" fill="none"/>)
      end

      def render_header_text(bounds, lines, font_color)
        center_x = bounds.x + (bounds.width / 2.0)
        lines.each_with_index.map do |line, idx|
          y = bounds.y + TOP_PADDING + (idx * HEADER_LINE_HEIGHT) - 4
          weight = (idx == lines.size - 1) ? "bold" : "normal"
          %(  <text x="#{center_x}" y="#{y}" text-anchor="middle" fill="#{font_color}" font-family="sans-serif" font-size="13" font-weight="#{weight}">#{escape(line)}</text>)
        end.join("\n            ")
      end

      def render_attribute_text(bounds, header_bottom, lines, font_color)
        return "" if lines.empty?

        left = bounds.x + 5
        lines.each_with_index.map do |line, idx|
          y = header_bottom + 14 + (idx * ATTR_LINE_HEIGHT)
          %(  <text x="#{left}" y="#{y}" text-anchor="start" fill="#{font_color}" font-family="sans-serif" font-size="12">#{escape(line)}</text>)
        end.join("\n            ")
      end

      def render_operation_text(bounds, attrs_bottom, lines, font_color)
        return "" if lines.empty?

        left = bounds.x + 5
        lines.each_with_index.map do |line, idx|
          y = attrs_bottom + 14 + (idx * OP_LINE_HEIGHT)
          %(  <text x="#{left}" y="#{y}" text-anchor="start" fill="#{font_color}" font-family="sans-serif" font-size="12">#{escape(line)}</text>)
        end.join("\n            ")
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
