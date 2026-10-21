# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the auto-generated legend block that EA renders from
        # a Text element whose StyleEx carries LegendOpts=. Layout
        # (verified against plateau reference SVGs):
        #
        #   ┌──────────────────────────────┐
        #   │            凡例              │  ← title baseline 20px below top
        #   │  ┌──┐                        │
        #   │  └──┘  GMLに定義されたクラス  │  ← item 0 (icon top + 30px)
        #   │  ┌──┐                        │
        #   │  └──┘  CityGMLに定義されたクラス
        #   │  ┌──┐                        │
        #   │  └──┘  i-URに定義されたクラス  │
        #   └──────────────────────────────┘
        #
        # Container: bounds.width × bounds.height, rx=3.
        # Each item: 17×17 icon rect + label text on the same line.
        # Item spacing is 19px (icon height 17 + 2 padding).
        class LegendRenderer
          CONTAINER_RX = 3
          ICON_SIZE = 17
          TITLE_Y_OFFSET = 20
          FIRST_ITEM_Y_OFFSET = 30
          ITEM_SPACING = 19
          ICON_X_OFFSET = 10
          ICON_LABEL_GAP = 22
          LABEL_BASELINE_FROM_ICON_TOP = 12
          DEFAULT_ITEM_FONT_SIZE = 9
          # The legend pen is not set explicitly: the panel inherits the pen
          # left by the previous drawing (round/bevel), or EA's initial pen
          # (square/miter) when the legend is the first thing painted. Held
          # across the corpus: 11 of 11 legends painted first are square, 105
          # of 105 painted later are round.
          INHERITED_STROKE = "stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel;"
          INITIAL_STROKE = "stroke-width:1;stroke-linecap:square;stroke-linejoin:miter;"

          def self.render(bounds, legend:, family:, canvas: nil, item_font: {}, first_painted: false)
            new(bounds, legend, family, canvas, item_font, first_painted: first_painted).to_svg
          end

          def initialize(bounds, legend, family, canvas, item_font = {}, first_painted: false)
            @bounds = bounds
            @legend = legend
            @family = family
            @canvas = canvas
            @pen = first_painted ? INITIAL_STROKE : INHERITED_STROKE
            @item_font = item_font[:size]&.nonzero? ? item_font : {}
          end

          def to_svg
            [container_layer, items_layer, title_layer].compact.join("\n")
          end

          private

          attr_reader :bounds, :legend, :family, :canvas, :item_font

          def container_layer
            body = format(
              '<rect x="%<x>s" y="%<y>s" width="%<w>s" height="%<h>s" rx="%<r>.2f" shape-rendering="auto"  />',
              x: fmt(bounds.x), y: fmt(bounds.y),
              w: fmt(bounds.width), h: fmt(bounds.height),
              r: CONTAINER_RX
            )
            %(<g style="#{container_style}">\n  #{body}\n</g>)
          end

          # One <g> per item — each item carries its own fill, so we
          # cannot consolidate them into a single group.
          def items_layer
            return nil if legend.items.empty?

            legend.items.map.with_index do |item, index|
              icon = icon_rect(item, index)
              label = item_label(item, index)
              [
                %(<g style="#{icon_style(item)}">\n  #{icon}\n</g>),
                %(<g style="#{label_style}">\n  #{label}\n</g>)
              ].join("\n")
            end.join("\n")
          end

          def title_layer
            %(<g style="#{label_style}">\n  #{title_text}\n</g>)
          end

          def container_style
            "#{@pen} " \
              "fill:#{container_fill};fill-opacity:1.00; " \
              "stroke:#{container_stroke}; stroke-opacity:1.00"
          end

          def icon_style(item)
            "#{@pen} " \
              "fill:#{icon_fill(item)};fill-opacity:1.00; " \
              "stroke:#000000; stroke-opacity:1.00"
          end

          def label_style
            "#{@pen} " \
              "fill:#{label_fill};fill-opacity:1.00; " \
              "stroke:#000000; stroke-opacity:0.00"
          end

          def container_fill
            BColDecoder.to_hex(legend.background_color) || "#F0F0F0"
          end

          def container_stroke
            BColDecoder.to_hex(legend.border_color) || "#D7D7D7"
          end

          def icon_fill(item)
            BColDecoder.to_hex(item.background_color) || "#FFFFFF"
          end

          def label_fill
            BColDecoder.to_hex(legend.font_color) || "#003060"
          end

          def icon_rect(_item, index)
            x = bounds.x + ICON_X_OFFSET
            y = item_top_y(index)
            format(
              '<rect x="%<x>s" y="%<y>s" width="%<w>d" height="%<h>d" rx="0.00" shape-rendering="auto"  />',
              x: fmt(x), y: fmt(y), w: ICON_SIZE, h: ICON_SIZE
            )
          end

          def item_label(item, index)
            x = bounds.x + ICON_X_OFFSET + ICON_LABEL_GAP
            y = item_top_y(index) + item_label_baseline
            build_text(item.name, x: x, y: y, size: item_font_size, weight: 0)
          end

          def item_label_baseline
            return LABEL_BASELINE_FROM_ICON_TOP unless (item_font[:unit] || "pt") == "pt"

            item_font[:logical_height] || LABEL_BASELINE_FROM_ICON_TOP
          end

          def title_text
            x = title_x
            y = bounds.y + TITLE_Y_OFFSET
            build_text(legend.title, x: x, y: y, size: title_font_size, weight: 700)
          end

          # EA centers the title over the ITEM BLOCK (icon left edge
          # to the right end of the widest label) by its INTEGER
          # textLength and floors x - verified against EA-published
          # reference SVGs.
          def title_x
            icon_left = bounds.x + ICON_X_OFFSET
            block_right = icon_left + ICON_LABEL_GAP +
                          widest_item_label_width
            block_left = icon_left
            (block_left + (block_right - block_left - title_text_width.round) / 2.0).floor
          end

          def estimated_width(text, size, weight: nil, logical_height: nil, text_family: family)
            TextRenderer.estimate_width(
              text, size, family: text_family, weight: weight,
                          logical_height: logical_height
            ).round
          end

          def widest_item_label_width
            logical_height = item_font[:logical_height] if (item_font[:unit] || "pt") == "pt"
            legend.items.map do |item|
              estimated_width(item.name, item_font_size, logical_height: logical_height)
            end.max || 0.0
          end

          def item_top_y(index)
            bounds.y + FIRST_ITEM_Y_OFFSET + (index * ITEM_SPACING)
          end

          def title_font_size
            return Ea::Model::Legend::DEFAULT_HEADING_SIZE unless legend.heading_size

            # HEADINGSIZE is stored in pixels; SVG legend text uses points.
            points = legend.heading_size * 72.0 / 96
            points == points.to_i ? points.to_i : points
          end

          def item_font_size
            item_font[:size] || DEFAULT_ITEM_FONT_SIZE
          end

          def title_text_width
            estimated_width(legend.title, title_font_size, weight: 700, text_family: heading_family)
          end

          def heading_family
            legend.heading_family || family
          end

          def build_text(content, x:, y:, size:, weight:)
            tx, ty = translate(x, y)
            size_unit = weight.zero? ? (item_font[:unit] || "pt") : "pt"
            TextRenderer.new(
              content: content.to_s, x: tx, y: ty,
              family: weight.zero? ? family : heading_family, size: size, size_unit: size_unit,
              weight: weight, fill: label_fill, logical_height: weight.zero? ? item_font[:logical_height] : nil
            ).to_svg
          end

          def translate(x, y)
            return [x, y] unless canvas

            [canvas.translate_x(x), canvas.translate_y(y)]
          end

          def fmt(value)
            Canvas.coord(value)
          end
        end
      end
    end
  end
end
