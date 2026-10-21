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
      # margin from the lowest element. The right edge also reaches
      # every connector end-label box (its position plus the stored
      # CX width) + LABEL_BOX_MARGIN 5, exact on the 7 PLATEAU diagrams
      # whose labels overhang the shapes (30D62231, 47E4600F,
      # 4881CEEE, 70C77F92, 846DD800, 88AF6BD7, AC2191E3). Below, the
      # same box (its top is the first baseline less the font height,
      # its height the stored CY) + 5 holds the canvas open on 95246DCF.
      module CanvasAnchor
        CONTENT_MARGIN = 10
        TEXT_MARGIN = 5
        ORIGIN_FLOOR = -5
        BOTTOM_MARGIN = 31
        LABEL_BOX_MARGIN = 5

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
        # max_y] in model coordinates (nil when absent). `label_reach` is
        # the [right, bottom] edge of the connector end-label boxes.
        def measured(shapes, texts, label_reach, bottom: BOTTOM_MARGIN)
          origin_x = origin(shapes && shapes[0], texts && texts[0])
          origin_y = origin(shapes && shapes[1], texts && texts[1])
          Canvas.new(min_x: origin_x, min_y: origin_y,
                     width: right_edge(shapes, label_reach) - origin_x,
                     height: bottom_edge(shapes, label_reach, bottom) - origin_y,
                     insets: [0, 0])
        end

        def right_edge(shapes, label_reach)
          [shapes && shapes[2] + CONTENT_MARGIN,
           label_reach && label_reach[0] + LABEL_BOX_MARGIN].compact.max
        end

        def bottom_edge(shapes, label_reach, bottom)
          [shapes[3] + bottom,
           label_reach && label_reach[1] + LABEL_BOX_MARGIN].compact.max
        end

        def origin(shape_min, text_min)
          lead = [shape_min && shape_min - CONTENT_MARGIN,
                  text_min && text_min - TEXT_MARGIN].compact.min
          [lead, ORIGIN_FLOOR].max
        end

        # The canvas anchored on the content drawn into `layers` (the
        # background excluded) and `label_reach`, or `canvas` itself
        # when there is nothing to measure.
        def reanchor(canvas, layers, label_reach, bottom: BOTTOM_MARGIN)
          extent = ContentExtent.measure(layers)
          return canvas unless extent.shapes

          shift = [canvas.origin_x, canvas.origin_y]
          measured(*[extent.shapes, extent.texts]
                     .map { |box| model_box(box, shift) }, label_reach,
                   bottom: bottom)
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
