# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Segment arithmetic for connector bridges: where two segments cross at
      # any slope, and where the arc chord sits on the carrier segment.
      module SegmentGeometry
        EPSILON = 1e-9

        module_function

        def distance(point, other)
          Math.hypot(point[0] - other[0], point[1] - other[1])
        end

        # 0 for a horizontal segment, 1 for a vertical one, nil otherwise.
        def axis_for(first, last)
          return 0 if first[1] == last[1] && first[0] != last[0]
          return 1 if first[0] == last[0] && first[1] != last[1]

          nil
        end

        # A proper crossing of two segments; parallel and collinear segments
        # never cross. Each span must leave `radius` of room either side.
        def crossing(first, last, start, finish, radius)
          point = axis_crossing(first, last, start, finish) ||
                  slanted_crossing(first, last, start, finish)
          return unless point && room?(point, first, last, radius) && room?(point, start, finish, radius)

          point
        end

        # The arc chord: one radius either side of the crossing along the
        # carrier's dominant axis. On a slanted carrier the other coordinate
        # follows the line, truncated to the integer grid (opening: 1157.49 and
        # 1157.82 both seat at 1157 in EA's export).
        def chord(first, last, crossing, radius)
          major = dominant_axis(first, last)
          step = last[major] > first[major] ? radius : -radius
          [crossing[major] - step, crossing[major] + step].map { |value| seat(first, last, major, value) }
        end

        def dominant_axis(first, last)
          (last[0] - first[0]).abs >= (last[1] - first[1]).abs ? 0 : 1
        end

        def axis_crossing(first, last, start, finish)
          axis = axis_for(first, last)
          return unless axis && axis_for(start, finish) == 1 - axis

          axis.zero? ? [start[0], first[1]] : [first[0], start[1]]
        end

        def slanted_crossing(first, last, start, finish)
          return if axis_for(first, last) && axis_for(start, finish)

          direction = delta(first, last)
          other = delta(start, finish)
          denominator = cross(direction, other)
          return if denominator.zero?

          advance(first, direction, cross(delta(first, start), other).fdiv(denominator))
        end

        def advance(origin, direction, fraction)
          [origin[0] + fraction * direction[0], origin[1] + fraction * direction[1]]
        end

        def delta(from, to)
          [to[0] - from[0], to[1] - from[1]]
        end

        def cross(one, other)
          one[0] * other[1] - one[1] * other[0]
        end

        def room?(point, first, last, radius)
          distance(point, first) >= radius && distance(point, last) >= radius &&
            [0, 1].all? { |axis| within?(point[axis], first[axis], last[axis]) }
        end

        def within?(value, from, to)
          minimum, maximum = [from, to].minmax
          value >= minimum - EPSILON && value <= maximum + EPSILON
        end

        def seat(first, last, major, value)
          minor = 1 - major
          point = [first[0], first[1]]
          point[major] = value
          point[minor] = minor_at(first, last, major, value) unless first[minor] == last[minor]
          point
        end

        def minor_at(first, last, major, value)
          minor = 1 - major
          slope = (last[minor] - first[minor]).fdiv(last[major] - first[major])
          (first[minor] + (value - first[major]) * slope + EPSILON).floor
        end
      end
    end
  end
end
