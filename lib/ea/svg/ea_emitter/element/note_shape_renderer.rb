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
        # Native EA emits the body and the folded corner as two polygons.
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
          FOLD_FILL = "#DCDCDC"
          TEXT_X_OFFSET = 5
          TEXT_Y_OFFSET = 12
          LINE_HEIGHT = 12

          # EA never sets the note pen: the outline takes the cap and join
          # left by the previous drawing, or the initial pen (square/miter)
          # when the note is the first thing painted. Checked on all six
          # native notes: 7C44AC09 first (square/miter), 7D960BD8 after
          # square/bevel icons (square/bevel), 676B9C9A, 926AFE38, 9DA6C553
          # and C028B286 after round/bevel shapes (round/bevel).
          INITIAL_PEN = %w[square miter].freeze
          PEN_PATTERN = /stroke-linecap:(\w+);stroke-linejoin:(\w+)/

          # The [cap, join] a rendered group leaves behind, or nil.
          def self.pen_of(group)
            match = PEN_PATTERN.match(group.to_s)
            match&.captures
          end

          def self.render(bounds, body:, fill:, stroke:, stroke_width:, family:, size:, text_fill:, pen: nil)
            new(bounds, body, fill, stroke, stroke_width, family, size, text_fill, pen || INITIAL_PEN).to_svg
          end

          def initialize(bounds, body, fill, stroke, stroke_width, family, size, text_fill, pen)
            @pen = pen
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
            [body_layer, fold_layer, text_layer].reject(&:empty?).join("\n")
          end

          private

          attr_reader :bounds, :body, :fill, :stroke, :stroke_width,
                      :family, :size, :text_fill

          def group_style(layer_fill)
            "stroke-width:#{stroke_width};stroke-linecap:#{@pen[0]};stroke-linejoin:#{@pen[1]}; " \
              "fill:#{layer_fill};fill-opacity:1.00; stroke:#{stroke}; stroke-opacity:1.00"
          end

          def body_layer
            %(<g style="#{group_style(fill)}">\n  #{polygon(body_points)}\n</g>)
          end

          def fold_layer
            %(<g style="#{group_style(FOLD_FILL)}">\n  #{polygon(fold_points)}\n</g>)
          end

          def text_layer
            text = text_block
            text.empty? ? "" : %(<g style="#{group_style(fill)}">\n  #{text}\n</g>)
          end

          # EA encodes the note silhouette as a <polygon> (all six
          # native Note placements in the PLATEAU and ArcGIS corpora),
          # starting at the top-left corner and running down first.
          def body_points
            left, top, right, bottom = edges
            [[left, top], [left, bottom], [right, bottom],
             [right, top + fold_size], [right - fold_size, top]]
          end

          def edges
            [bounds.x, bounds.y, bounds.x + bounds.width, bounds.y + bounds.height]
          end

          # The folded corner is a separate triangle, filled light
          # grey regardless of the note's own fill.
          def fold_points
            r = bounds.x + bounds.width
            y = bounds.y
            [[r - fold_size, y], [r - fold_size, y + fold_size], [r, y + fold_size]]
          end

          def fold_size
            [FOLD_SIZE, bounds.width / 3, bounds.height / 3].min
          end

          def polygon(points)
            list = points.map { |px, py| "#{Canvas.coord(px)} #{Canvas.coord(py)}" }.join(" ")
            %(<polygon points="#{list}" shape-rendering="auto"   style="fill-rule:evenodd;"/>)
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
