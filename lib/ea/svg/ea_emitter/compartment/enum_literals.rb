# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Enumeration literal compartment: divider line + "literals"
        # italic header + each literal name. Skipped when the
        # classifier has no literals or the geometry cannot fit them.
        module EnumLiterals
          module_function

          # EA: literal rows sit directly under the header divider,
          # 13px apart at 7pt (attr rows use 14), first row at
          # divider + 14. No compartment divider, no header label.
          LITERAL_LINE_OFFSET = 6

          def render(context)
            return nil unless context.enum_literals.any?
            return nil unless context.geometry.enum_literal_first_y

            render_literals_block(context)
          end

          def render_literals_block(context)
            line_h = context.size + LITERAL_LINE_OFFSET
            text_blocks = []
            context.enum_literals.each_with_index do |literal, idx|
              y = context.geometry.enum_literal_first_y + (idx * line_h)
              text_blocks << visibility_placeholder(context, y)
              text_blocks << literal_name_text(context, literal, y)
            end
            wrap_group(text_blocks, context.theme.text_color)
          end

          def visibility_placeholder(context, y)
            TextRenderer.new(
              content: " ",
              x: context.bounds.x + (context.theme.attribute_spec.visibility_x_offset || 5),
              y: y,
              family: context.family, size: context.size, size_unit: context.size_unit,
              fill: context.theme.text_color,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor
            ).to_svg
          end

          def literal_name_text(context, literal, y)
            TextRenderer.new(
              content: literal.name.to_s,
              x: context.bounds.x + (context.theme.attribute_spec.content_x_offset || 26),
              y: y,
              family: context.family, size: context.size, size_unit: context.size_unit,
              fill: context.theme.text_color,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor
            ).to_svg
          end

          def wrap_group(text_blocks, text_color)
            style = "stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; " \
                    "fill:#{text_color};fill-opacity:1.00; " \
                    "stroke:#000000; stroke-opacity:0.00"
            %(<g style="#{style}">\n#{text_blocks.join("\n")}\n</g>)
          end
        end
      end
    end
  end
end
