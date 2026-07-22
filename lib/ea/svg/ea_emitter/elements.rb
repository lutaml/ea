# frozen_string_literal: true

require "ostruct"

module Ea
  module Svg
    module EaEmitter
      # Emits the elements layer: for each DiagramElement on the
      # diagram, emits the EA-shape group (filled rect) plus the
      # EA-text group (stereotype + name + attributes + operations).
      #
      # Each element is rendered in z_order (ascending). Output
      # follows EA's pattern of layered groups per element:
      #
      #   <g style="fill:COLOR;..."><rect x y w h/></g>
      #   <g style="fill:#000000;..."><text>...</text></g>
      #   <g style="..."><path d="M x y L x2 y2"/></g>   (divider)
      #   <g style="..."><text>attr1</text>...</g>
      class Elements
        DEFAULT_FILL = "#FFFFFF"
        DEFAULT_STROKE = "#000000"
        DEFAULT_FONT_FAMILY = "Calibri"
        DEFAULT_FONT_SIZE = 13

        attr_reader :diagram, :model_index, :canvas

        def initialize(diagram, model_index:, canvas: nil)
          @diagram = diagram
          @model_index = model_index
          @canvas = canvas
        end

        def render
          ordered_elements.map { |e| render_one(e) }.join("\n")
        end

        private

        def ordered_elements
          (diagram.elements || []).sort_by { |e| e.z_order || 0 }
        end

        def render_one(element)
          raw_bounds = element.bounds || element.image_bounds
          return "" unless raw_bounds

          bounds = translate_bounds(raw_bounds)
          classifier = model_element_for(element)
          fill = color_from_ea(element.background_color) || fill_for_classifier(classifier)
          stroke = color_from_ea(element.line_color) || DEFAULT_STROKE
          stroke_width = element.line_width || 2
          size = element.font_size || DEFAULT_FONT_SIZE
          size = DEFAULT_FONT_SIZE if size.nil? || size.zero?
          family = element.font_family || DEFAULT_FONT_FAMILY

          h_lines = classifier ? header_lines(classifier) : []
          a_lines = classifier ? build_attr_lines(classifier) : []
          line_h = size + 4
          header_first_y = bounds.y + line_h
          header_bottom = header_first_y + ([h_lines.size, 1].max - 1) * line_h + 8
          divider_y = h_lines.empty? ? nil : header_bottom
          attr_first_y = divider_y ? divider_y + size + 5 : bounds.y + line_h + 8

          parts = []
          parts << render_shape_group(bounds, fill, stroke, stroke_width)
          parts << render_header_text(h_lines, bounds, header_first_y, family, size) unless h_lines.empty?
          parts << render_divider(bounds, divider_y, stroke, stroke_width) if divider_y
          parts << render_attribute_text(a_lines, bounds, attr_first_y, family, size) unless a_lines.empty?
          parts.compact.join("\n")
        end

        def render_shape_group(bounds, fill, stroke, stroke_width)
          %(<g style="stroke-width:#{stroke_width};stroke-linecap:round;stroke-linejoin:bevel; fill:#{fill};fill-opacity:1.00; stroke:#{stroke}; stroke-opacity:1.00">\n  <rect x="#{bounds.x}" y="#{bounds.y}" width="#{bounds.width}" height="#{bounds.height}" rx="0.00" shape-rendering="auto"  />\n</g>)
        end

        def render_header_text(lines, bounds, first_y, family, size)
          line_h = size + 4
          text_blocks = lines.each_with_index.map do |(text, style), idx|
            weight = style == :bold ? 700 : 400
            font_style = style == :italic ? "italic" : "normal"
            y = first_y + (idx * line_h)
            %(  <text x="#{format('%.2f', bounds.x + (bounds.width / 2.0))}" y="#{format('%.2f', y)}" textLength="#{(text.length * size * 0.55).round}" style="font-family:#{family}; font-weight:#{weight}; font-style:#{font_style}; font-size:#{size}px; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00 stroke-width:0; white-space: pre;" xml:space="preserve">#{escape(text)}</text>)
          end
          %(<g style="stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00">\n#{text_blocks.join("\n")}\n</g>)
        end

        def render_divider(bounds, y, stroke, stroke_width)
          %(<g style="stroke-width:#{stroke_width};stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:0.00; stroke:#{stroke}; stroke-opacity:1.00">\n  <path d="M #{format('%.2f', bounds.x)} #{format('%.2f', y)} L #{format('%.2f', bounds.x + bounds.width)} #{format('%.2f', y)}" shape-rendering="auto"/>\n</g>)
        end

        def render_attribute_text(lines, bounds, first_y, family, size)
          line_h = size + 4
          text_blocks = lines.each_with_index.map do |line, idx|
            y = first_y + (idx * line_h)
            %(  <text x="#{format('%.2f', bounds.x + 5)}" y="#{format('%.2f', y)}" textLength="#{(line.strip.length * size * 0.55).round}" style="font-family:#{family}; font-weight:400; font-style:normal; font-size:#{size}px; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00 stroke-width:0; white-space: pre;" xml:space="preserve">#{escape(line.strip)}</text>)
          end
          %(<g style="stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00">\n#{text_blocks.join("\n")}\n</g>)
        end

        def build_attr_lines(classifier)
          return [] unless classifier.properties

          classifier.properties.map do |p|
            "+ #{p.name}: #{p.type_name || ''} #{mult_text(p)}"
          end
        end

        def header_lines(classifier)
          lines = []
          if classifier.is_a?(Ea::Model::Klass) && classifier.is_abstract
            lines << ["_#{classifier.name}", :italic]
          elsif classifier.stereotype_refs&.any?
            lines << ["«#{classifier.stereotype_refs.first}»", :normal]
            lines << [(classifier.qualified_name || classifier.name).to_s, :bold]
          else
            lines << [(classifier.qualified_name || classifier.name).to_s, :bold]
          end
          lines
        end

        def mult_text(p)
          lower = p.multiplicity_lower
          upper = p.multiplicity_upper
          return "" if lower.nil? && upper.nil?
          return "" if lower == 1 && upper == 1

          "[#{lower || 0}..#{upper == -1 ? "*" : upper}]"
        end

        def fill_for_classifier(classifier)
          return DEFAULT_FILL unless classifier

          stereotype = primary_stereotype(classifier)
          return DEFAULT_FILL unless stereotype

          stereotype_color_resolver.fill_for(stereotype)
        end

        def stereotype_color_resolver
          @stereotype_color_resolver ||= Ea::Svg::StereotypeColorResolver.new
        end

        def primary_stereotype(classifier)
          refs = classifier.stereotype_refs
          return nil if refs.nil? || refs.empty?

          refs.first.to_s.split("::").last
        end

        def model_element_for(element)
          ref = element.model_element_ref
          return nil unless ref

          candidate = model_index[ref]
          return nil unless candidate.is_a?(Ea::Model::Classifier)

          candidate
        end

        def color_from_ea(bgr_int)
          return nil if bgr_int.nil?

          r = bgr_int & 0xff
          g = (bgr_int >> 8) & 0xff
          b = (bgr_int >> 16) & 0xff
          format("#%02X%02X%02X", r, g, b)
        end

        def escape(text)
          return "" if text.nil?

          text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("\"", "&quot;")
        end

        def translate_bounds(b)
          return b unless canvas

          OpenStruct.new(
            x: canvas.translate_x(b.x),
            y: canvas.translate_y(b.y),
            width: b.width,
            height: b.height
          )
        end
      end
    end
  end
end
