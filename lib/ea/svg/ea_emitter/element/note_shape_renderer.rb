# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the shape `<g>` for a Note element: a folded-corner
        # rect plus body text. EA renders every Note element as a
        # dog-eared rectangle (top-right corner folded in) with the
        # note text wrapped inside.
        #
        # Layout:
        #
        #   ┌──────────────────┐
        #   │                  ┐
        #   │ body text lines   │
        #   │                  │
        #   └──────────────────-┘
        #
        class NoteShapeRenderer
          FOLD_SIZE = 12
          TEXT_X_OFFSET = 5
          TEXT_Y_OFFSET = 12
          LINE_HEIGHT = 12

          def self.render(bounds, body:, fill:, stroke:, stroke_width:, family:, size:, text_fill:)
            new(bounds, body, fill, stroke, stroke_width, family, size, text_fill).to_svg
          end

          def initialize(bounds, body, fill, stroke, stroke_width, family, size, text_fill)
            @bounds = bounds
            @body = body.to_s
            @fill = fill
            @stroke = stroke
            @stroke_width = stroke_width
            @family = family
            @size = size
            @text_fill = text_fill
          end

          def to_svg
            %(<g style="#{group_style}">\n  #{path_body}\n  #{fold_line}\n  #{text_block}\n</g>)
          end

          private

          attr_reader :bounds, :body, :fill, :stroke, :stroke_width,
                      :family, :size, :text_fill

          def group_style
            "stroke-width:#{stroke_width};stroke-linecap:square;stroke-linejoin:bevel; " \
              "fill:#{fill};fill-opacity:1.00; stroke:#{stroke}; stroke-opacity:1.00"
          end

          # Folded-corner body emitted as a closed <path> matching
          # EA's encoding (not <polygon>). EA uses M..L..L..Z with
          # stroke-linejoin=bevel for the dog-eared silhouette.
          def path_body
            x = bounds.x
            y = bounds.y
            w = bounds.width
            h = bounds.height
            fold = [FOLD_SIZE, w / 3, h / 3].min
            d = "M #{Canvas.coord(x)} #{Canvas.coord(y)} " \
                "L #{Canvas.coord(x + w - fold)} #{Canvas.coord(y)} " \
                "L #{Canvas.coord(x + w)} #{Canvas.coord(y + fold)} " \
                "L #{Canvas.coord(x + w)} #{Canvas.coord(y + h)} " \
                "L #{Canvas.coord(x)} #{Canvas.coord(y + h)} " \
                "L #{Canvas.coord(x)} #{Canvas.coord(y)} Z"
            %(<path d="#{d}" shape-rendering="auto"/>)
          end

          # Diagonal line marking the fold.
          def fold_line
            x = bounds.x
            y = bounds.y
            w = bounds.width
            fold = [FOLD_SIZE, w / 3, bounds.height / 3].min
            %(<path d="M #{Canvas.coord(x + w - fold)} #{Canvas.coord(y)} L #{Canvas.coord(x + w)} #{Canvas.coord(y + fold)}" shape-rendering="auto"/>)
          end

          def text_block
            lines = body_lines
            return "" if lines.empty?

            texts = lines.each_with_index.map do |line, idx|
              y = bounds.y + TEXT_Y_OFFSET + (idx * LINE_HEIGHT)
              TextRenderer.new(content: line,
                                x: bounds.x + TEXT_X_OFFSET,
                                y: y,
                                family: family,
                                size: size,
                                fill: text_fill).to_svg
            end
            texts.join("\n  ")
          end

          # Naive word-wrap based on character count. EA's actual
          # wrapping uses GDI text metrics; this is an approximation.
          def body_lines
            return [] if body.empty?

            max_chars = [(bounds.width / (size.to_f * 0.6)).floor, 10].max
            body.split(/\n/).flat_map do |para|
              para.gsub(/(.{1,#{max_chars}})(\s+|$)/, "\\1\n").strip.split(/\n/)
            end
          end
        end
      end
    end
  end
end
