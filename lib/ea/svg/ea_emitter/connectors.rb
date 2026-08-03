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

        attr_reader :diagram, :canvas, :grouped, :stroke_width

        def initialize(diagram, canvas: nil, grouped: true, stroke_width: 2)
          @diagram = diagram
          @canvas = canvas
          @grouped = grouped
          @stroke_width = stroke_width
        end

        def layers
          paths = visible_connectors.filter_map { |c| path_for(c) }
          return [] if paths.empty?

          if grouped
            [Layer.new(style_key: LINE_STYLE_KEY, style: line_style,
                       body: paths.join("\n  "))]
          else
            paths.map do |path|
              Layer.new(style_key: LINE_STYLE_KEY, style: line_style, body: path)
            end
          end
        end

        def line_style
          "stroke-width:#{stroke_width};stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:0.00; stroke:#000000; stroke-opacity:1.00"
        end

        # Backwards-compatible render — joins all layers' `<g>`.
        def render
          layers.map(&:to_svg).join("\n")
        end

        private

        def visible_connectors
          (diagram.connectors || []).select(&:renderable?)
        end

        def path_for(connector)
          pts = waypoints_for(connector)
          return nil if pts.size < 2

          d = pts.each_with_index.map do |p, idx|
            x, y = translate_point(p)
            "#{idx.zero? ? 'M' : 'L'} #{Canvas.coord(x)} #{Canvas.coord(y)}"
          end.join(" ")
          %(<path d="#{d}" shape-rendering="auto"/>)
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
