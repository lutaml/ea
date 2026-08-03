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

          def render(context)
            return nil unless context.enum_literals.any?
            return nil unless context.geometry.enum_literal_first_y

            [
              Element::DividerRenderer.render(
                context.bounds,
                y: context.geometry.enum_divider_y,
                stroke: context.stroke,
                stroke_width: context.stroke_width
              ),
              render_literals_block(context)
            ].join("\n")
          end

          def render_literals_block(context)
            line_h = context.size + (context.theme.compartments.attr_line_offset || 4)
            text_blocks = [literal_header_text(context)]
            context.enum_literals.each_with_index do |literal, idx|
              y = context.geometry.enum_literal_first_y + ((idx + 1) * line_h)
              text_blocks << visibility_placeholder(context, y)
              text_blocks << literal_name_text(context, literal, y)
            end
            wrap_group(text_blocks, context.theme.text_color)
          end

          def literal_header_text(context)
            TextRenderer.new(
              content: "literals",
              x: context.bounds.x + (context.bounds.width / 2.0) -
                (8 * context.size * context.theme.text_width_factor) / 2,
              y: context.geometry.enum_literal_first_y,
              family: context.family, size: context.size, size_unit: context.size_unit,
              style: "italic", fill: context.theme.text_color,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor
            ).to_svg
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
