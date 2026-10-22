# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Measures the extent of emitted SVG content: the points EA draws
      # shapes through (rect, path M/L/C/A end points, polygon, ellipse)
      # and the box of every text run (left edge, top = baseline - font
      # height, right = left + textLength). EA anchors an unframed
      # export's canvas on this extent.
      class ContentExtent
        NUMBER = /-?\d*\.?\d+(?:[eE][-+]?\d+)?/
        ELEMENT = /<(rect|path|polygon|polyline|ellipse|text)\b([^>]*)>/
        ATTRIBUTE = /\b([\w:-]+)="([^"]*)"/
        PATH_COMMAND = /([MLACHVZ])([^MLACHVZ]*)/
        PX_PER_PT = 96 / 72.0

        # Each box is [min_x, min_y, max_x, max_y] or nil when the
        # content has no shape (or no text).
        attr_reader :shapes, :texts

        def self.measure(svg_fragments)
          shape_points = []
          text_boxes = []
          svg_fragments.each do |svg|
            svg.to_s.scan(ELEMENT) do |kind, attrs|
              attributes = attrs.scan(ATTRIBUTE).to_h
              next text_boxes << text_box(attributes) if kind == "text"

              shape_points.concat(points(kind, attributes))
            end
          end
          new(shape_points, text_boxes)
        end

        def self.points(kind, attrs)
          case kind
          when "rect" then rect_points(attrs)
          when "path" then path_points(attrs["d"].to_s)
          when "polygon", "polyline" then pairs(attrs["points"].to_s)
          else ellipse_points(attrs)
          end
        end

        def self.rect_points(attrs)
          left, top, wide, high = %w[x y width height].map { |k| attrs[k].to_f }
          [[left, top], [left + wide, top + high]]
        end

        def self.ellipse_points(attrs)
          cx, cy, rx, ry = %w[cx cy rx ry].map { |k| attrs[k].to_f }
          [[cx - rx, cy - ry], [cx + rx, cy + ry]]
        end

        def self.pairs(body)
          body.scan(NUMBER).map(&:to_f).each_slice(2).select { |pair| pair.size == 2 }
        end

        def self.path_points(path_data)
          path_data.scan(PATH_COMMAND).flat_map do |command, body|
            numbers = body.scan(NUMBER).map(&:to_f)
            case command
            when "M", "L" then numbers.each_slice(2).select { |pair| pair.size == 2 }
            when "C" then end_points(numbers, 6)
            when "A" then end_points(numbers, 7)
            else []
            end
          end
        end

        # The segment end point only: a Bezier's control points lie
        # outside the drawn curve and EA does not count them (basic
        # E325B9D8, hand-drawn style: 504 x 274 natively, 508 x 278
        # with the control points).
        def self.end_points(numbers, stride)
          numbers.each_slice(stride).select { |a| a.size == stride }.map { |a| a.last(2) }
        end

        def self.text_box(attrs)
          style = attrs["style"].to_s
          size = style[/font-size:([\d.]+)/, 1].to_f
          size *= PX_PER_PT if style[/font-size:[\d.]+(pt|px)/, 1] == "pt"
          left = attrs["x"].to_f
          base = attrs["y"].to_f
          [left, base - size.ceil, left + attrs["textLength"].to_f, base]
        end

        def initialize(shape_points, text_boxes)
          @shapes = box(shape_points.map(&:first), shape_points.map(&:last))
          @texts = box(text_boxes.map(&:first) + text_boxes.map { |b| b[2] },
                       text_boxes.map { |b| b[1] } + text_boxes.map { |b| b[3] })
        end

        private

        def box(columns, rows)
          return nil if columns.empty?

          [columns.min, rows.min, columns.max, rows.max]
        end
      end
    end
  end
end
