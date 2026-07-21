# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Computes the canvas dimensions for the root <svg> element.
      # Union of all element image_bounds (the padded bounds EA
      # uses for the visual box), with a 10 px outer margin.
      # Emits cm dimensions (px / 28.346 at 72 DPI).
      Canvas = Struct.new(:min_x, :min_y, :width, :height, keyword_init: true) do
        PX_PER_CM = 28.3464567

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
          margin = 10
          new(
            min_x: (xs.min || 0) - margin,
            min_y: (ys.min || 0) - margin,
            width: (xs.max - xs.min) + (2 * margin),
            height: (ys.max - ys.min) + (2 * margin)
          )
        end

        def view_box
          "#{min_x} #{min_y} #{width} #{height}"
        end

        def width_cm
          format_cm(width)
        end

        def height_cm
          format_cm(height)
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
