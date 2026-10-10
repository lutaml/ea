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
            row_y = context.geometry.enum_literal_first_y
            # EA renders a centered italic "literals" caption above
            # the rows when the literals carry stored code values
            # (t_attribute.Default); bare literal lists render the
            # rows directly. Corpus-verified (PT_TypeOfSA:
            # "literals" caption + "ServingParcel = SP" rows;
            # CV_SequenceType: bare rows, no caption).
            if caption?(context)
              text_blocks << caption_text(context, row_y)
              row_y += line_h
            end
            context.enum_literals.each_with_index do |literal, idx|
              y = row_y + (idx * line_h)
              text_blocks << visibility_placeholder(context, y)
              text_blocks << literal_name_text(context, literal, y)
            end
            wrap_group(text_blocks, context.theme.text_color)
          end

          def caption?(context)
            values_caption?(context) || grown?(context)
          end

          # EA draws the 'literals' caption on every enum box it
          # re-lays (grown height) - corpus 8/8 grown=caption. Boxes
          # keeping stored size keep their stored caption state,
          # captured by the stored literal values.
          def grown?(context)
            stored = context.element&.bounds
            return false unless stored

            context.bounds.height > stored.height + 4
          end

          def values_caption?(context)
            context.enum_literals.any? do |l|
              value = l.value.to_s
              !value.empty? && value != l.name.to_s
            end
          end

          def caption_text(context, y)
            content = "literals"
            len = TextRenderer.estimate_width(content, context.size, nil,
                                              family: context.family).round
            x = (context.bounds.x + (context.bounds.width - len) / 2.0).floor
            TextRenderer.new(
              content: content,
              x: x, y: y,
              family: context.family, size: context.size, size_unit: context.size_unit,
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
              family: context.family, size: context.size, size_unit: context.size_unit,
              fill: context.theme.text_color,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor
            ).to_svg
          end

          def literal_name_text(context, literal, y)
            content = literal_display(literal)
            TextRenderer.new(
              content: content,
              x: context.bounds.x + (context.theme.attribute_spec.content_x_offset || 26),
              y: y,
              family: context.family, size: context.size, size_unit: context.size_unit,
              fill: context.theme.text_color,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor
            ).to_svg
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
