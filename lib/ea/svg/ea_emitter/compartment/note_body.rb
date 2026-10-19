# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Note body text wrapped inside a Note element's bounds.
        # Renders only when the host element is a Note with a
        # non-empty body.
        module NoteBody
          # Native notes put the first baseline this far below the note
          # top plus the font's GDI cell ascent (Arial 9pt/10pt +27,
          # Cambria 7pt +24, Carlito 9pt +26).
          TEXT_TOP = 14

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
            # Lines fit bounds.width - 4. Pitch is the GDI cell height
            # of the note font and the first baseline sits TEXT_TOP
            # plus the cell ascent below the top; fonts without
            # vertical data keep pitch size+7 and offset size+9. Each
            # empty source line adds one blank pitch row.
            usable = context.bounds.width - 4
            size = context.size
            family = context.family
            pitch, first_offset = vertical_layout(context)
            y_index = 0
            paragraphs = NoteHtml.paragraphs(body)
            paragraphs.flat_map do |para|
              lines = wrap_paragraph(para.text, usable, size, context.family,
                                     logical_height: context.logical_height)
              paragraph_svg = lines.each_with_index.map do |line, i|
                y = context.bounds.y + first_offset + ((y_index + i) * pitch)
                TextRenderer.new(
                  content: line,
                  x: context.bounds.x + context.theme.note.text_x_offset,
                  y: y,
                  family: context.family, size: context.size,
                  size_unit: context.size_unit,
                  logical_height: context.logical_height,
                  fill: context.theme.text_color,
                  stroke_in_text: context.theme.stroke_in_text_color,
                  width_factor: context.theme.text_width_factor
                ).to_svg
              end
              y_index += lines.size + para.gap
              paragraph_svg
            end
          end

          # [pitch, first-baseline offset] for the note font.
          def vertical_layout(context)
            size = context.size
            height = context.logical_height
            height ||= Ea::Fonts::Metrics.gdi_logical_height(size) if context.size_unit == "pt"
            ascent, descent = Ea::Fonts::Metrics.gdi_cell_metrics(context.family, height)
            return [size + 7, size + 9] unless ascent

            [ascent + descent, TEXT_TOP + ascent]
          end
          module_function :vertical_layout

          # Wrap at whitespace until native script-specific break metrics are
          # established. Every word but the paragraph's last carries its
          # trailing space into the fit test.
          def wrap_paragraph(para, usable, size, family, logical_height: nil)
            lines = []
            current = ""
            words = para.strip.split(/\s+/)
            words.each_with_index do |word, index|
              candidate = current.empty? ? word : "#{current} #{word}"
              trailing = index < words.size - 1 ? " " : ""
              width = TextRenderer.estimate_width("#{candidate}#{trailing}", size, nil,
                                                  family: family, logical_height: logical_height).round
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
