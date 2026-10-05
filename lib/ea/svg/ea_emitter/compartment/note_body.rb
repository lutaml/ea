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

          # EA wraps note text by MEASURED width (Carlito advances),
          # not character count: lines break at the last word whose
          # cumulative integer textLength fits bounds.width - 15.
          # Verified against EA-published reference SVGs.
          def wrapped_lines(context, body)
            usable = context.bounds.width - 15
            size = context.size
            family = context.family
            # EA's note body pitch and first-line offset scale with
            # the note font (9pt notes: pitch 16 = size+7, first line
            # at bounds.y + 18 = size+9 - 9BA1CE54).
            pitch = context.size + 7
            first_offset = context.size + 9
            body.to_s.split(/\n/).flat_map do |para|
              wrap_paragraph(para, usable, size, context.family)
            end.each_with_index.map do |line, idx|
              y = context.bounds.y + first_offset + (idx * pitch)
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

          def wrap_paragraph(para, usable, size, family)
            words = para.strip.split(/\s+/)
            lines = []
            current = ""
            words.each do |word|
              candidate = current.empty? ? word : "#{current} #{word}"
              width = TextRenderer.estimate_width(candidate, size, nil,
                                                  family: family).round
              if current.empty? || width <= usable
                current = candidate
              else
                lines << current
                current = word
              end
            end
            lines << current unless current.empty?
            lines
          end
          module_function :wrap_paragraph

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
