# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Computes the canvas dimensions for the root <svg> element
      # and the translation offset to apply to every coordinate so
      # the top-left of the union lands at (0, 0) — matching EA's
      # output convention.
      Canvas = Struct.new(:min_x, :min_y, :width, :height, keyword_init: true) do
        PX_PER_CM = 28.3464567
        PADDING = 10

        # Compute the canvas by unioning all element image bounds and
        # connector waypoints. The translation is set to the
        # negative of the union's top-left so all coordinates
        # become non-negative in the rendered output.
        def self.from(diagram)
          points = []
          (diagram.elements || []).each do |e|
            b = e.image_bounds || e.bounds
            next unless b

            points << [b.x, b.y]
            points << [b.x + b.width, b.y + b.height]
          end
          (diagram.connectors || []).each do |c|
            (c.waypoints || []).each do |wp|
              next unless wp.position

              points << [wp.position.x, wp.position.y]
            end
          end
          return new(min_x: 0, min_y: 0, width: 1, height: 1) if points.empty?

          xs = points.map(&:first)
          ys = points.map(&:last)
          min_x = (xs.min || 0)
          min_y = (ys.min || 0)
          max_x = (xs.max || 0)
          max_y = (ys.max || 0)
          new(
            min_x: min_x,
            min_y: min_y,
            width: (max_x - min_x) + (2 * PADDING),
            height: (max_y - min_y) + (2 * PADDING)
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
