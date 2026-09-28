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
                          stroke_in_text: "#000000", width_factor: 0.612,
                          line_offset: 6)
            line_h = size + line_offset
            text_blocks = lines.each_with_index.map do |(text, style), idx|
              weight = case style
                       when :bold, :bold_italic then weight_bold
                       else weight_normal
                       end
              font_style = (style == :italic || style == :bold_italic) ? "italic" : "normal"
              # EA spaces the line AFTER a right-aligned ghost 6px
              # wider (ghost +13, next +32 at 7pt) - verified against
              # EA-published reference SVGs.
              y = first_y + (idx * line_h) +
                  (idx >= 1 && lines.first.last == :italic ? 6 : 0)
              x = if style == :italic
                    # EA right-aligns the off-canvas parent ghost at
                    # the box's right edge by its integer textLength.
                    bounds.x + bounds.width -
                      Ea::Svg::EaEmitter::TextRenderer.estimate_width(
                        text, size, width_factor,
                        family: family, weight: weight, style: font_style
                      ).round
                  else
                    center_x_for(text, bounds, size, width_factor,
                                 family: family, weight: weight,
                                 style: font_style)
                  end
              TextRenderer.new(
                content: text,
                x: x, y: y,
                family: family, size: size, size_unit: size_unit,
                weight: weight, style: font_style, fill: fill,
                stroke_in_text: stroke_in_text, width_factor: width_factor
              ).to_svg
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          # EA centers text by its INTEGER textLength and floors the
          # resulting x (verified exact against EA-published SVGs).
          def self.center_x_for(text, bounds, size, width_factor,
                                family: nil, weight: nil, style: nil)
            len = Ea::Svg::EaEmitter::TextRenderer.estimate_width(
              text, size, width_factor, family: family, weight: weight, style: style
            ).round
            (bounds.x + (bounds.width - len) / 2.0).floor
          end
          private_class_method :center_x_for
        end
      end
    end
  end
end
