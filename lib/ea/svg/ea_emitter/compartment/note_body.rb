# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Note body text wrapped inside a Note element's bounds.
        # Renders only when the host element is a Note with a
        # non-empty body.
        module NoteBody
          module_function

          def render(context)
            return nil if context.model_element.is_a?(Ea::Model::Note) &&
                          context.model_element.legend

            body = context.note_body
            return nil unless body

            text_blocks = wrapped_lines(context, body)
            %(<g style="#{group_style(context)}">\n#{text_blocks.join("\n")}\n</g>)
          end

          def wrapped_lines(context, body)
            max_chars = [(context.bounds.width / (context.size * 0.6)).floor, 10].max
            body.to_s.split(/\n/).flat_map do |para|
              para.gsub(/(.{1,#{max_chars}})(\s+|$)/, "\\1\n").strip.split(/\n/)
            end.each_with_index.map do |line, idx|
              y = context.bounds.y + context.theme.note.text_y_offset +
                  (idx * context.theme.note.line_height)
              TextRenderer.new(
                content: line,
                x: context.bounds.x + context.theme.note.text_x_offset,
                y: y,
                family: context.family, size: context.size, size_unit: context.size_unit,
                fill: context.theme.text_color,
                stroke_in_text: context.theme.stroke_in_text_color,
                width_factor: context.theme.text_width_factor
              ).to_svg
            end
          end

          def group_style(context)
            "stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; " \
              "fill:#{context.theme.text_color};fill-opacity:1.00; " \
              "stroke:#000000; stroke-opacity:0.00"
          end
        end
      end
    end
  end
end
