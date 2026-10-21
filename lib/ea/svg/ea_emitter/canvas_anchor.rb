# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Canvas policy of an UNFRAMED export (EA's "Save Diagram Image"
      # without the automatic frame: the PLATEAU native SVGs). Measured
      # on the 220 native SVGs, where it reproduces the origin of 205 of
      # 215 diagrams from the native content alone (the other 10 sit at
      # the floor below):
      #
      #   origin = max(min(shape_min - 10, text_left_or_top - 5), -5)
      #
      # in model coordinates, per axis. Shapes are rect/path/polygon/
      # ellipse points; a text box runs from its left edge and from
      # baseline minus the rounded font height. The right margin is 10
      # from the shapes.
      #
      # EMPIRICAL FITS (no saved selector was found in any QEA table):
      # BOTTOM_MARGIN 31 is only the fallback; BottomMargin picks the
      # margin from the lowest element; LABEL_RIGHT_MARGIN 23 is the label text
      # right edge + 21..23 seen on 4 diagrams whose labels overhang
      # the shapes.
      module CanvasAnchor
        CONTENT_MARGIN = 10
        TEXT_MARGIN = 5
        ORIGIN_FLOOR = -5
        BOTTOM_MARGIN = 31
        LABEL_RIGHT_MARGIN = 23

        module_function

        # Where content starting at `content_min` lands on the canvas.
        def inset(content_min)
          content_min - [content_min - CONTENT_MARGIN, ORIGIN_FLOOR].max
        end

        # Canvas for shapes spanning the given model-space extent (the
        # stored element rects, before any drawn content is measured).
        def stored(min_x, min_y, max_x, max_y, bottom: BOTTOM_MARGIN)
          left = inset(min_x)
          top = inset(min_y)
          Canvas.new(min_x: min_x, min_y: min_y,
                     width: (max_x - min_x) + left + CONTENT_MARGIN,
                     height: (max_y - min_y) + top + bottom,
                     insets: [left, top])
        end

        # Canvas for measured content, each box [min_x, min_y, max_x,
        # max_y] in model coordinates (nil when absent). `labels` is the
        # connector-label subset of `texts`.
        def measured(shapes, texts, labels, bottom: BOTTOM_MARGIN)
          origin_x = origin(shapes && shapes[0], texts && texts[0])
          origin_y = origin(shapes && shapes[1], texts && texts[1])
          Canvas.new(min_x: origin_x, min_y: origin_y,
                     width: right_edge(shapes, labels) - origin_x,
                     height: shapes[3] + bottom - origin_y,
                     insets: [0, 0])
        end

        def right_edge(shapes, labels)
          [shapes && shapes[2] + CONTENT_MARGIN,
           labels && labels[2] + LABEL_RIGHT_MARGIN].compact.max
        end

        def origin(shape_min, text_min)
          lead = [shape_min && shape_min - CONTENT_MARGIN,
                  text_min && text_min - TEXT_MARGIN].compact.min
          [lead, ORIGIN_FLOOR].max
        end

        # The canvas anchored on the content drawn into `layers` (the
        # background excluded) and `label_layers`, or `canvas` itself
        # when there is nothing to measure.
        def reanchor(canvas, layers, label_layers, bottom: BOTTOM_MARGIN)
          extent = ContentExtent.measure(layers)
          return canvas unless extent.shapes

          shift = [canvas.origin_x, canvas.origin_y]
          measured(*[extent.shapes, extent.texts,
                     ContentExtent.measure(label_layers).texts]
                     .map { |box| model_box(box, shift) }, bottom: bottom)
        end

        def model_box(box, shift)
          return nil unless box

          [box[0] + shift[0], box[1] + shift[1],
           box[2] + shift[0], box[3] + shift[1]]
        end

        def same_canvas?(one, other)
          [one.origin_x, one.origin_y, one.width, one.height] ==
            [other.origin_x, other.origin_y, other.width, other.height]
        end
      end
    end
  end
end
