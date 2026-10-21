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
        #
        # A link saved with `LWidth=0` defers to the connector's own saved
        # pen (`t_connector.IsBold`, XMI `<appearance linewidth>`), which
        # DiagramConnector#line_width carries. Checked on connector 438 in
        # 9400D9BC and FEBE5726 (IsBold=2, native stroke-width 2); the 314
        # LWidth=0 links with IsBold=0 stay one pixel.
        def self.stroke_width_for(connector, default)
          style = connector.style || {}
          raw = style[:lwidth] || style["lwidth"]
          return default if raw.to_s.strip.empty?
          return connector.line_width if raw.to_i.zero? && connector.line_width.to_i.positive?

          [raw.to_i, 1].max
        end

        DEFAULT_STROKE = "#000000"

        # EA strokes a connector and its markers in the colour stored in
        # the diagram link style (`Color`, a BGR integer; -1 = default).
        # Checked on the #69738C links of 5DA1E7A7, 73025C5A, C31C1314
        # and E7AABA98.
        def self.stroke_color_for(connector)
          raw = connector.line_color
          raw = (connector.style || {})[:color] if raw.nil?
          return DEFAULT_STROKE if raw.nil? || raw.to_s.strip.empty?

          Element::BColDecoder.to_hex(raw.to_i) || DEFAULT_STROKE
        end

        # Layer key for a style group: the plain key at the default
        # width and colour, suffixed otherwise so layers of different
        # widths or colours never merge.
        def self.layer_key(key, width, default, color = DEFAULT_STROKE)
          key = :"#{key}_w#{width}" unless width == default
          color == DEFAULT_STROKE ? key : :"#{key}_c#{color.delete('#')}"
        end

        def layers
          styles = paths_with_styles.map { |_connector, style, path| [style, path] }

          if grouped
            styles.group_by(&:first).map do |(width, dashed, color), entries|
              line_layer(width, dashed, color, entries.map(&:last).join("\n  "))
            end
          else
            styles.map { |(width, dashed, color), path| line_layer(width, dashed, color, path) }
          end
        end

        # One `[connector, Layer]` pair per drawn connector, in
        # diagram link order: EA paints each connector (line, then its
        # heads) in turn, so the sequencer interleaves these with the
        # marker layers instead of bucketing every line first.
        def connector_layers
          paths_with_styles.map do |connector, (width, dashed, color), path|
            [connector, line_layer(width, dashed, color, path)]
          end
        end

        # EA draws dashed lines with square caps and round joins.
        def line_style(width = stroke_width, color = DEFAULT_STROKE, dashed: false)
          cap_join = dashed ? "square;stroke-linejoin:round" : "round;stroke-linejoin:bevel"
          "stroke-width:#{width};stroke-linecap:#{cap_join}; " \
            "fill:#000000;fill-opacity:0.00; stroke:#{color}; stroke-opacity:1.00"
        end

        # Backwards-compatible render — joins all layers' `<g>`.
        def render
          layers.map(&:to_svg).join("\n")
        end

        private

        def paths_with_styles
          routes = visible_connectors.filter_map do |connector|
            points = resolved_points(connector)
            [connector, points.map { |point| translate_point(point) }] if points.size >= 2
          end
          bridges = ConnectorBridges.new(diagram, routes)
          routes.map do |connector, points|
            [connector,
             [self.class.stroke_width_for(connector, stroke_width), dashed?(connector),
              self.class.stroke_color_for(connector)],
             path_for(connector, points, bridges)]
          end
        end

        def line_layer(width, dashed, color, body)
          key = dashed ? :connector_line_dashed : LINE_STYLE_KEY
          style = line_style(width, color, dashed: dashed)
          style += ";stroke-dasharray:6,3" if dashed
          Layer.new(style_key: self.class.layer_key(key, width, stroke_width, color),
                    style: style, body: body)
        end

        def dashed?(connector)
          return true if connector.style.to_h[:association_class_ref]
          return true if connector.connector_type == "Dependency"
          return false unless connector.connector_type == "Package"

          relationship = model_index && model_index[connector.relationship_ref]
          relationship&.stereotype == "import"
        end

        def visible_connectors
          (diagram.connectors || []).select(&:renderable?)
        end

        def resolved_points(connector)
          pts = ConnectorRedock.pairs_for(connector, diagram, model_index,
                                          drawn_bounds) ||
                waypoints_for(connector)
          ConnectorRedock.row_slot_adjust(pts, connector, diagram,
                                          model_index, drawn_bounds,
                                          divider_y_by_ref) || pts
        end

        def path_for(connector, pts, bridges)
          %(<path d="#{bridges.path_for(connector, pts)}" shape-rendering="auto"/>)
        end

        def waypoints_for(connector)
          (connector.waypoints || []).filter_map do |wp|
            next unless wp.position

            [wp.position.x, wp.position.y]
          end
        end

        def translate_point(point)
          return point unless @canvas

          [@canvas.translate_x(point[0]), @canvas.translate_y(point[1])]
        end
      end
    end
  end
end
