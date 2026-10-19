# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits connector line `<path>` elements grouped per line-style.
      # Returns an Array of `Layer` structs.
      #
      # Default mode (`grouped: true`) consolidates all same-style
      # paths into ONE `<g>` element — matching EA's encoding for
      # diagrams with many similarly-styled connectors.
      #
      # Pass `grouped: false` for per-connector grouping (one `<g>`
      # per line, used when strict per-entity interleaving with
      # markers is required).
      class Connectors
        LINE_STYLE_KEY = :connector_line

        attr_reader :diagram, :canvas, :grouped, :stroke_width, :drawn_bounds,
                    :model_index, :divider_y_by_ref

        def initialize(diagram, canvas: nil, grouped: true, stroke_width: 2,
                       drawn_bounds: nil, model_index: nil,
                       divider_y_by_ref: nil)
          @diagram = diagram
          @canvas = canvas
          @grouped = grouped
          @stroke_width = stroke_width
          @drawn_bounds = drawn_bounds
          @model_index = model_index
          @divider_y_by_ref = divider_y_by_ref
        end

        # EA draws each connector (and its markers) with the pen width
        # stored in the diagram link style (`LWidth`); links without
        # the field keep the diagram default.
        def self.stroke_width_for(connector, default)
          style = connector.style || {}
          raw = style[:lwidth] || style["lwidth"]
          return default if raw.to_s.strip.empty?

          [raw.to_i, 1].max
        end

        # Layer key for a style group: the plain key at the default
        # width, suffixed with the width otherwise so layers of
        # different widths never merge.
        def self.layer_key(key, width, default)
          width == default ? key : :"#{key}_w#{width}"
        end

        def layers
          styles = paths_with_styles

          if grouped
            styles.group_by(&:first).map do |(width, dashed), entries|
              line_layer(width, dashed, entries.map(&:last).join("\n  "))
            end
          else
            styles.map { |(width, dashed), path| line_layer(width, dashed, path) }
          end
        end

        def line_style(width = stroke_width)
          "stroke-width:#{width};stroke-linecap:round;stroke-linejoin:bevel; " \
            "fill:#000000;fill-opacity:0.00; stroke:#000000; stroke-opacity:1.00"
        end

        # Backwards-compatible render — joins all layers' `<g>`.
        def render
          layers.map(&:to_svg).join("\n")
        end

        private

        def paths_with_styles
          visible_connectors.filter_map do |connector|
            path = path_for(connector)
            next unless path

            [[self.class.stroke_width_for(connector, stroke_width), dashed?(connector)], path]
          end
        end

        def line_layer(width, dashed, body)
          key = dashed ? :connector_line_dashed : LINE_STYLE_KEY
          style = line_style(width)
          style += ";stroke-dasharray:6,3" if dashed
          Layer.new(style_key: self.class.layer_key(key, width, stroke_width),
                    style: style, body: body)
        end

        def dashed?(connector)
          return true if connector.connector_type == "Dependency"
          return false unless connector.connector_type == "Package"

          relationship = model_index && model_index[connector.relationship_ref]
          relationship&.stereotype == "import"
        end

        def visible_connectors
          (diagram.connectors || []).select(&:renderable?)
        end

        def path_for(connector)
          pts = ConnectorRedock.pairs_for(connector, diagram, model_index,
                                          drawn_bounds) ||
                waypoints_for(connector)
          pts = ConnectorRedock.row_slot_adjust(pts, connector, diagram,
                                                model_index, drawn_bounds,
                                                divider_y_by_ref) || pts
          return nil if pts.size < 2

          # DIRECT (auto-routed straight) connectors: EA writes the
          # segment TARGET-FIRST with a trailing zero-length repeat —
          # "M target L source M target" (B6847577, E58034A3,
          # 8CF27BE8). Same pixels as source-first; only the byte
          # order differs, so reversal lives here at the emitter and
          # the marker anchoring (source = first waypoint) is
          # untouched.
          if pts.size == 2 && direct?(connector)
            x1, y1 = translate_point(pts.first)
            x2, y2 = translate_point(pts.last)
            d = "M #{Canvas.coord(x2)} #{Canvas.coord(y2)} L #{Canvas.coord(x1)} #{Canvas.coord(y1)} " \
                "M #{Canvas.coord(x2)} #{Canvas.coord(y2)}"
          else
            d = pts.each_with_index.map do |p, idx|
              x, y = translate_point(p)
              "#{idx.zero? ? 'M' : 'L'} #{Canvas.coord(x)} #{Canvas.coord(y)}"
            end.join(" ")
          end
          %(<path d="#{d}" shape-rendering="auto"/>)
        end

        def direct?(connector)
          style = connector.style || {}
          style.key?(:direct) || style.key?("direct")
        end

        def waypoints_for(connector)
          (connector.waypoints || []).filter_map do |wp|
            next unless wp.position

            [wp.position.x, wp.position.y]
          end
        end

        def translate_point(p)
          return p unless @canvas

          [@canvas.translate_x(p[0]), @canvas.translate_y(p[1])]
        end
      end
    end
  end
end
