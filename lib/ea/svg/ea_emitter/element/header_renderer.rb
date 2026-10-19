# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the header text `<g>` containing stereotype + class
        # name lines. Lines + styling computed by HeaderLines.
        #
        # EA centers header text within the element bounds (computing
        # the left edge from text-width approximation since SVG text
        # x= is the start position, not the center).
        class HeaderRenderer
          HeaderLine = Struct.new(:text, :style, :x, :y, :text_length,
                                  :weight, :font_style, keyword_init: true)

          def self.render(lines, bounds:, first_y:, family:,
                          size:, size_unit: "pt", logical_height: nil,
                          fill: "#000000", weight_normal: 400, weight_bold: 700,
                          stroke_in_text: "#000000", width_factor: 0.612,
                          line_offset: 6, default_signal_header: false)
            logical_height = nil unless size_unit == "pt"
            layout = line_layout(
              lines, bounds: bounds, first_y: first_y, family: family,
                     size: size, size_unit: size_unit, logical_height: logical_height,
                     weight_normal: weight_normal, weight_bold: weight_bold,
                     width_factor: width_factor, line_offset: line_offset,
                     default_signal_header: default_signal_header
            )
            text_blocks = layout.map do |line|
              TextRenderer.new(
                content: line.text,
                x: line.x, y: line.y,
                family: family, size: size, size_unit: size_unit, logical_height: logical_height,
                weight: line.weight, style: line.font_style, fill: fill,
                stroke_in_text: stroke_in_text, width_factor: width_factor,
                text_length: line.text_length
              ).to_svg
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          # Returns the exact integer placement and width used for each
          # emitted header line so dependent compartments can align to it.
          def self.line_layout(lines, bounds:, first_y:, family:, size:,
                               size_unit: "pt", logical_height: nil,
                               weight_normal: 400, weight_bold: 700,
                               width_factor: 0.612, line_offset: 6, default_signal_header: false)
            logical_height = nil unless size_unit == "pt"
            line_h = Ea::Fonts::Metrics.compartment_line_height(
              size, family: family, unit: size_unit, offset: line_offset,
                    logical_height: logical_height
            )
            # Native default Cambria 7pt Signals use a 15px header pitch.
            # Keep explicit fonts, logical heights and layout overrides intact.
            if default_signal_header && family == "Cambria" && size == 7 &&
               size_unit == "pt" && logical_height.nil? && line_offset == 6 &&
               first_y == bounds.y + 13 && lines.size == 2 &&
               lines.first == ["«signal»", :normal] && lines.last.last == :bold
              first_y -= 1
              line_h = 15
            end
            ghost_shift = HeaderLines.parent_ghost_gap(lines)
            lines.each_with_index.map do |(text, style), idx|
              weight = %i[bold bold_italic].include?(style) ? weight_bold : weight_normal
              font_style = %i[italic italic_tight bold_italic].include?(style) ? "italic" : "normal"
              text_length = TextRenderer.estimate_width(
                text, size, width_factor, family: family, weight: weight,
                                          style: font_style, logical_height: logical_height
              ).round
              y = first_y + (idx * line_h) +
                  (idx >= 1 && ghost_shift.positive? ? ghost_shift : 0)
              x = if %i[italic italic_tight].include?(style)
                    bounds.x + bounds.width - 3 - text_length
                  else
                    center_x_for(text_length, bounds)
                  end
              HeaderLine.new(text: text, style: style, x: x, y: y,
                             text_length: text_length, weight: weight,
                             font_style: font_style)
            end
          end

          # EA centers text by its INTEGER textLength and floors the
          # resulting x (verified exact against EA-published SVGs).
          def self.center_x_for(text_length, bounds)
            (bounds.x + (bounds.width - text_length) / 2.0).floor
          end
          private_class_method :center_x_for
        end
      end
    end
  end
end
