# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits a hand-drawn style shape `<path>` for elements on
        # diagrams that have HandDraw=1 in their StyleEx. EA renders
        # each element as a closed `<path>` with cubic beziers per
        # side (slight wave) instead of a clean `<rect>`. Used by
        # Domain Model diagrams.
        class HandDrawShapeRenderer
          WAVE_AMPLITUDE = 2
          WAVE_LENGTH = 70

          def self.render(bounds, fill:, stroke:, stroke_width:)
            new(bounds, fill, stroke, stroke_width).to_svg
          end

          def initialize(bounds, fill, stroke, stroke_width)
            @bounds = bounds
            @fill = fill
            @stroke = stroke
            @stroke_width = stroke_width
          end

          def to_svg
            %(<g style="#{group_style}">\n  #{shape_path}\n</g>)
          end

          private

          attr_reader :bounds, :fill, :stroke, :stroke_width

          def group_style
            "stroke-width:#{stroke_width};stroke-linecap:round;" \
              "stroke-linejoin:bevel; fill:#{fill};fill-opacity:1.00;" \
              " stroke:#{stroke}; stroke-opacity:1.00"
          end

          # Approximation of EA's hand-drawn border. Each side is a
          # cubic bezier from one corner to the next, with control
          # points pulled slightly inward to give a wavy silhouette.
          # The exact ref encoding uses many short S-curves; this
          # emits 4 C commands (one per side) which is shape-count
          # compatible.
          def shape_path
            x1 = bounds.x.to_f
            y1 = bounds.y.to_f
            x2 = x1 + bounds.width.to_f
            y2 = y1 + bounds.height.to_f
            cx1 = x1 + bounds.width.to_f / 2
            cy1 = y1 + bounds.height.to_f / 2
            d = "M #{coord(x1)} #{coord(y1)} " \
                "C #{coord(x1 + WAVE_LENGTH)} #{coord(y1 - WAVE_AMPLITUDE)} " \
                "#{coord(cx1 + WAVE_LENGTH / 2)} #{coord(y1 + WAVE_AMPLITUDE)} " \
                "#{coord(x2)} #{coord(y1)} " \
                "C #{coord(x2 + WAVE_AMPLITUDE)} #{coord(y1 + WAVE_LENGTH)} " \
                "#{coord(x2 - WAVE_AMPLITUDE)} #{coord(cy1 + WAVE_LENGTH / 2)} " \
                "#{coord(x2)} #{coord(y2)} " \
                "C #{coord(x2 - WAVE_LENGTH)} #{coord(y2 + WAVE_AMPLITUDE)} " \
                "#{coord(cx1 - WAVE_LENGTH / 2)} #{coord(y2 - WAVE_AMPLITUDE)} " \
                "#{coord(x1)} #{coord(y2)} " \
                "C #{coord(x1 - WAVE_AMPLITUDE)} #{coord(y2 - WAVE_LENGTH)} " \
                "#{coord(x1 + WAVE_AMPLITUDE)} #{coord(cy1 - WAVE_LENGTH / 2)} " \
                "#{coord(x1)} #{coord(y1)} Z"
            %(<path d="#{d}" shape-rendering="auto"/>)
          end

          def coord(value)
            Ea::Svg::EaEmitter::Canvas.coord(value)
          end
        end
      end
    end
  end
end
