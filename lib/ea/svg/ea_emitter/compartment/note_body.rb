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
            # Lines fit bounds.width - 4. Pitch and
            # first-line offset scale with the note font (9pt: pitch
            # 16 = size+7, first line at bounds.y + 18 = size+9), and
            # each paragraph break adds one blank pitch row
            # (paragraph 2 starts 32 after the last line of
            # paragraph 1).
            usable = context.bounds.width - 4
            size = context.size
            family = context.family
            pitch = size + 7
            first_offset = size + 9
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
              y_index += lines.size + (para.tight ? 0 : 1)
              paragraph_svg
            end
          end

          # A line breaks between words and beside any CJK character; a
          # run of other characters never splits. Every word but the
          # paragraph's last carries its trailing space into the fit test.
          def wrap_paragraph(para, usable, size, family, logical_height: nil)
            lines = []
            current = ""
            break_pieces(para.strip.split(/\s+/)).each do |piece|
              candidate = current.empty? ? piece.text : "#{current}#{piece.glue}#{piece.text}"
              width = TextRenderer.estimate_width("#{candidate}#{piece.trailing}", size, nil,
                                                  family: family, logical_height: logical_height).round
              if current.empty? || width <= usable
                current = candidate
              else
                lines << current
                current = piece.text
              end
            end
            lines << current unless current.empty?
            lines
          end
          module_function :wrap_paragraph

          Piece = Struct.new(:text, :glue, :trailing)

          def break_pieces(words)
            words.each_with_index.flat_map do |word, word_index|
              units = units_of(word)
              units.each_with_index.map do |unit, unit_index|
                Piece.new(unit,
                          unit_index.zero? && word_index.positive? ? " " : "",
                          unit_index == units.size - 1 && word_index < words.size - 1 ? " " : "")
              end
            end
          end
          module_function :break_pieces

          # Single CJK characters and the runs of other characters between.
          def units_of(text)
            text.each_char.chunk_while { |a, b| !cjk?(a) && !cjk?(b) }.map(&:join)
          end
          module_function :units_of

          def cjk?(char)
            Ea::Fonts::Metrics.cjk?(char.ord)
          end
          module_function :cjk?

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
