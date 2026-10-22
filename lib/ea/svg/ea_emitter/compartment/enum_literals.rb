# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Enumeration literal compartment: divider line + "literals"
        # italic header + each literal name. Skipped when the
        # classifier has no literals or no content geometry.
        module EnumLiterals
          # The pen the first group of this compartment leaves behind.
          def self.pen(_context)
            Pen::ROUND_BEVEL
          end

          module_function

          # Caption and literal rows share the same baseline spacing.
          LITERAL_LINE_OFFSET = 6

          def render(context)
            return nil unless context.enum_literals.any?
            return nil unless context.geometry.enum_literal_first_y

            render_literals_block(context)
          end

          def render_literals_block(context)
            line_h = Ea::Fonts::Metrics.compartment_line_height(
              context.size, family: context.family, unit: context.size_unit, logical_height: context.logical_height,
                            offset: LITERAL_LINE_OFFSET
            )
            text_blocks = []
            row_y = context.geometry.enum_literal_first_y
            text_blocks << caption_text(context, row_y)
            row_y += line_h
            context.enum_literals.each_with_index do |literal, idx|
              y = row_y + (idx * line_h)
              text_blocks << visibility_placeholder(context, y)
              text_blocks << literal_name_text(context, literal, y)
            end
            wrap_group(text_blocks, context.theme.text_color)
          end

          def caption_text(context, y)
            content = "literals"
            len = TextRenderer.estimate_width(content, context.size, nil,
                                              family: context.family, logical_height: context.logical_height).round
            x = (context.bounds.x + (context.bounds.width - len) / 2.0).floor
            TextRenderer.new(
              content: content,
              x: x, y: y,
              family: context.family, size: context.size,
              size_unit: context.size_unit, logical_height: context.logical_height,
              fill: context.theme.text_color,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor,
              style: "italic"
            ).to_svg
          end

          def visibility_placeholder(context, y)
            TextRenderer.new(
              content: " ",
              x: context.bounds.x + (context.theme.attribute_spec.visibility_x_offset || 5),
              y: y,
              family: context.family, size: context.size,
              size_unit: context.size_unit, logical_height: context.logical_height,
              fill: context.theme.text_color,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor
            ).to_svg
          end

          def literal_name_text(context, literal, y)
            content = literal_display(literal)
            TextRenderer.new(
              content: content,
              x: context.bounds.x + content_x_offset(context.theme, context.size, context.size_unit, context.family),
              y: y,
              family: context.family, size: context.size,
              size_unit: context.size_unit, logical_height: context.logical_height,
              fill: context.theme.text_color,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor
            ).to_svg
          end

          def content_width(literals, theme:, size:, family:, **font_options)
            return nil if literals.empty?

            logical_height = font_options[:logical_height] if font_options[:size_unit] == "pt"
            length = literals.map do |literal|
              TextRenderer.estimate_width(literal_display(literal), size, theme.text_width_factor,
                                          family: family, weight: 400, style: "normal",
                                          logical_height: logical_height).round
            end.max
            content_x_offset(theme, size, font_options[:size_unit], family) + length + 5
          end

          def content_x_offset(theme, size, size_unit, family)
            # EA seats literal names at the attribute-name content x, with the
            # attribute row point-size increment.
            offset = theme.attribute_content_x_offset || 26
            offset += 2 * (size - 7) if size_unit == "pt"
            offset -= 1 if Ea::Fonts::Metrics.compact_compartment_font?(size, family: family, unit: size_unit)
            offset
          end

          # EA shows "Name = Code" for literals with a stored
          # default value; bare names otherwise.
          def literal_display(literal)
            value = literal.value.to_s
            return literal.name.to_s if value.empty? || value == literal.name.to_s

            "#{literal.name} = #{value}"
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
