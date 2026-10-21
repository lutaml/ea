# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Bridges decorate resolved render paths; stored routes and marker seats
      # remain centerlines. The connector's stored order key (reproducing EA's
      # exported link order), rather than style group order, determines which
      # connector passes over a crossing.
      class ConnectorBridges
        RADIUS = 6
        PHANTOM = :phantom

        def initialize(_diagram, routes)
          @routes = routes.map { |connector, points| [connector, points, priority_for(connector)] }
        end

        def path_for(connector, points)
          priority = priority_for(connector)
          return centerline(connector, points) unless priority

          segments = points.each_cons(2).map do |first, last|
            crossings_for(connector, priority, first, last)
          end
          return centerline(connector, points) if segments.all?(&:empty?)

          serialize(points, segments)
        end

        private

        def centerline(connector, points)
          seats = points.map { |point| coordinates(point) }
          # Direct lines retain EA's target-first repeat and source-first model.
          if points.size == 2 && direct?(connector)
            "M #{seats.last} L #{seats.first} M #{seats.last}"
          else
            "M #{seats.join(" L ")}"
          end
        end

        def direct?(connector)
          style = connector.style || {}
          style.key?(:direct) || style.key?("direct")
        end

        def serialize(points, segments)
          commands = ["M #{coordinates(points.first)}"]
          points.each_cons(2).with_index do |(first, last), index|
            segments[index].each do |crossing|
              commands.concat(arc_commands(first, last, crossing))
            end
            commands << "L #{coordinates(last)}"
          end
          commands.join(" ")
        end

        # nil or empty: no bridge decision for this connector.
        def priority_for(connector)
          return PHANTOM if phantom?(connector)

          connector.paint_order if connector.paint_order&.any?
        end

        # A phantom (relationship without a link row) has no stored order; it
        # is appended after every link in the export, so it passes over them.
        def phantom?(connector)
          connector.paint_order.nil?
        end

        def crossings_for(connector, priority, first, last)
          crossings = lower_routes(connector, priority).flat_map do |_partner, points, _order|
            points.each_cons(2).filter_map do |start, finish|
              crossing(first, last, start, finish)
            end
          end
          separate_crossings(crossings).sort_by { |point| distance(point, first) }
        end

        # The order key is only proven across different start placements, so
        # connectors leaving the same placement make no carrier decision.
        def lower_routes(connector, priority)
          return keyed_routes(connector) if priority == PHANTOM

          @routes.select do |partner, _points, order|
            !partner.equal?(connector) && order.is_a?(Array) && order.size == priority.size &&
              !same_source?(connector, partner) && (order <=> priority).negative?
          end
        end

        def keyed_routes(connector)
          @routes.select { |partner, _points, order| !partner.equal?(connector) && order.is_a?(Array) }
        end

        def same_source?(connector, partner)
          connector.source_element_ref && connector.source_element_ref == partner.source_element_ref
        end

        # Partners crossing at one point share a single arc (0BE81AC5 draws one
        # arc for three coincident verticals). Distinct crossings whose spans
        # overlap are all suppressed so route order cannot select one of
        # several ambiguous arcs.
        def separate_crossings(crossings)
          crossings = crossings.uniq { |point| point.map { |value| value.round(6) } }
          crossings.reject.with_index do |point, index|
            crossings.each_with_index.any? do |other, other_index|
              index != other_index && distance(point, other) < 2 * RADIUS
            end
          end
        end

        def crossing(first, last, start, finish)
          SegmentGeometry.crossing(first, last, start, finish, RADIUS)
        end

        def distance(point, other)
          SegmentGeometry.distance(point, other)
        end

        def arc_commands(first, last, crossing)
          start, finish = SegmentGeometry.chord(first, last, crossing, RADIUS)
          ["L #{coordinates(start)}", "A #{RADIUS} #{RADIUS} 180 0 0 #{coordinates(finish)}"]
        end

        def coordinates(point)
          point.map { |value| Canvas.coord(value) }.join(" ")
        end
      end
    end
  end
end
