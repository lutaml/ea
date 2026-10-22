# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Note text compartment. When diagram.show_notes is true,
        # renders the classifier's documentation note (from
        # t_object.Note) as wrapped text lines in the element body.
        # Lines are estimated by character width and split at word
        # boundaries to fit the element bounds.
        module NoteText
          # The pen the first group of this compartment leaves behind.
          def self.pen(_context)
            Pen::ROUND_BEVEL
          end

          X_PADDING = 5
          HAND_DRAW_X_PADDING = 10
          Y_FIRST_OFFSET = 15
          HAND_DRAW_Y_FIRST_OFFSET = 11
          LINE_OFFSET = 13
          CHAR_WIDTH_FACTOR = 0.55

          module_function

          def render(context)
            return nil unless show_notes?(context)
            return nil unless context.classifier&.is_a?(Ea::Model::Classifier)

            notes = note_bodies(context.classifier)
            return nil if notes.empty?

            x_padding, y_offset = note_offsets(context)
            first_y = context.geometry.attr_first_y + y_offset
            bounds = context.bounds
            fill = context.theme.attribute_text_color
            usable_width = bounds.width - (x_padding * 2)
            max_chars = (usable_width / (context.size * CHAR_WIDTH_FACTOR)).floor

            texts = []
            y = first_y
            notes.each do |body|
              wrapped_lines(body, max_chars).each do |line|
                texts << build_text(line, bounds.x + x_padding, y, context, fill)
                y += LINE_OFFSET
              end
            end
            wrap_group(texts.join("\n"), fill)
          end

          # Native hand-drawn classifiers use a wider documentation inset.
          def note_offsets(context)
            context.diagram.hand_draw ? [HAND_DRAW_X_PADDING, HAND_DRAW_Y_FIRST_OFFSET] : [X_PADDING, Y_FIRST_OFFSET]
          end
          module_function :note_offsets

          def show_notes?(context)
            context.diagram && context.diagram.show_notes
          end
          module_function :show_notes?

          def note_bodies(classifier)
            (classifier.annotations || []).filter_map do |a|
              body = a.body.to_s.strip
              body.empty? ? nil : body
            end
          end
          module_function :note_bodies

          # Word-wrap text at max_chars, preserving word boundaries.
          def wrapped_lines(text, max_chars)
            return [text] if text.length <= max_chars

            words = text.split(" ")
            lines = []
            current = ""
            words.each do |word|
              if current.empty?
                current = word
              elsif (current + " " + word).length <= max_chars
                current = "#{current} #{word}"
              else
                # EA retains the consumed word separator on a wrapped
                # documentation row, including it in SVG textLength.
                lines << "#{current} "
                current = word
              end
            end
            lines << current unless current.empty?
            lines
          end
          module_function :wrapped_lines

          def build_text(content, x_pos, y_pos, context, fill)
            TextRenderer.new(
              content: content,
              x: x_pos, y: y_pos,
              family: context.family, size: context.size,
              size_unit: context.size_unit, fill: fill,
              style: "italic"
            ).to_svg
          end
          module_function :build_text

          def wrap_group(body, fill)
            style = "stroke-width:1;stroke-linecap:round;" \
                    "stroke-linejoin:bevel; fill:#{fill};" \
                    "fill-opacity:1.00; stroke:#000000;" \
                    " stroke-opacity:0.00"
            %(<g style="#{style}">\n#{body}\n</g>)
          end
          module_function :wrap_group
        end
      end
    end
  end
end
