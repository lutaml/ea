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
          def self.render(lines, bounds:, first_y:, family:,
                          size:, size_unit: "pt",
                          fill: "#000000", weight_normal: 400, weight_bold: 700,
                          stroke_in_text: "#000000", width_factor: 0.65,
                          line_offset: 6)
            line_h = size + line_offset
            text_blocks = lines.each_with_index.map do |(text, style), idx|
              weight = case style
                       when :bold, :bold_italic then weight_bold
                       else weight_normal
                       end
              font_style = (style == :italic || style == :bold_italic) ? "italic" : "normal"
              y = first_y + (idx * line_h)
              centered_x = center_x_for(text, bounds, size, width_factor)
              TextRenderer.new(
                content: text,
                x: centered_x, y: y,
                family: family, size: size, size_unit: size_unit,
                weight: weight, style: font_style, fill: fill,
                stroke_in_text: stroke_in_text, width_factor: width_factor
              ).to_svg
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          def self.center_x_for(text, bounds, size, width_factor)
            text_width = Ea::Svg::EaEmitter::TextRenderer.estimate_width(text, size, width_factor)
            bounds.x + (bounds.width - text_width) / 2.0
          end
          private_class_method :center_x_for
        end
      end
    end
  end
end
