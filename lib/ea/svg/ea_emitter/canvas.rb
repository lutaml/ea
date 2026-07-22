# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      Canvas = Struct.new(:min_x, :min_y, :width, :height, keyword_init: true) do
        PX_PER_CM = 28.3464567
        PADDING = 10

        def self.from(diagram)
          points = []
          (diagram.elements || []).each do |e|
            b = e.bounds || e.image_bounds
            next unless b

            points << [b.x, b.y]
            points << [b.x + b.width, b.y + b.height]
          end
          return new(min_x: 0, min_y: 0, width: 1, height: 1) if points.empty?

          xs = points.map(&:first)
          ys = points.map(&:last)
          new(
            min_x: (xs.min || 0),
            min_y: (ys.min || 0),
            width: (xs.max - xs.min) + (2 * PADDING),
            height: (ys.max - ys.min) + (2 * PADDING)
          )
        end

        def view_box
          "0 0 #{width} #{height}"
        end

        def width_cm
          format_cm(width)
        end

        def height_cm
          format_cm(height)
        end

        def translate_x(x)
          x - min_x + PADDING
        end

        def translate_y(y)
          y - min_y + PADDING
        end

        private

        def format_cm(px)
          return "0cm" if px.nil? || px.zero?

          cm = (px / PX_PER_CM.to_f)
          format("%.2fcm", cm)
        end
      end
    end
  end
end
