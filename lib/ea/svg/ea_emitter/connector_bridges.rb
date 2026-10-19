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
          connector.paint_order if connector.paint_order&.any?
        end

        def crossings_for(connector, priority, first, last)
          axis = axis_for(first, last)
          return [] unless axis

          crossings = lower_routes(connector, priority).flat_map do |_partner, points, _order|
            points.each_cons(2).filter_map do |start, finish|
              crossing(first, last, start, finish, axis)
            end
          end
          separate_crossings(crossings, axis).sort_by { |point| (point[axis] - first[axis]).abs }
        end

        # The order key is only proven across different start placements, so
        # connectors leaving the same placement make no carrier decision.
        def lower_routes(connector, priority)
          @routes.select do |partner, _points, order|
            !partner.equal?(connector) && order && order.size == priority.size &&
              !same_source?(connector, partner) && (order <=> priority).negative?
          end
        end

        def same_source?(connector, partner)
          connector.source_element_ref && connector.source_element_ref == partner.source_element_ref
        end

        # Suppress both overlapping spans, including coincident crossings,
        # so route order cannot select one of several ambiguous arcs.
        def separate_crossings(crossings, axis)
          crossings.reject.with_index do |point, index|
            crossings.each_with_index.any? do |other, other_index|
              index != other_index && (point[axis] - other[axis]).abs < 2 * RADIUS
            end
          end
        end

        def crossing(first, last, start, finish, axis)
          return unless axis_for(start, finish) == 1 - axis

          point = axis.zero? ? [start[0], first[1]] : [first[0], start[1]]
          return unless segment_interior?(point, first, last, axis) &&
                        segment_interior?(point, start, finish, 1 - axis)

          point
        end

        def segment_interior?(point, first, last, axis)
          interior?(point[axis], first[axis], last[axis])
        end

        def interior?(value, first, last)
          minimum, maximum = [first, last].minmax
          value > minimum && value < maximum &&
            value - minimum >= RADIUS && maximum - value >= RADIUS
        end

        def axis_for(first, last)
          return 0 if first[1] == last[1] && first[0] != last[0]
          return 1 if first[0] == last[0] && first[1] != last[1]

          nil
        end

        def arc_commands(first, last, crossing)
          axis = axis_for(first, last)
          direction = last[axis] > first[axis] ? 1 : -1
          start = crossing.dup
          finish = crossing.dup
          start[axis] -= direction * RADIUS
          finish[axis] += direction * RADIUS
          ["L #{coordinates(start)}", "A #{RADIUS} #{RADIUS} 180 0 0 #{coordinates(finish)}"]
        end

        def coordinates(point)
          point.map { |value| Canvas.coord(value) }.join(" ")
        end
      end
    end
  end
end
