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
        COINCIDENT_LEFTOVER = 3
        NEAR_COINCIDENT = 2
        Bridge = Struct.new(:start, :finish, :leftover)

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

        # EA also draws NoteLink, Package and two-point Dependency lines
        # target-first with the repeat (9DA6C553 NoteLink; 2A5E0832 and
        # DFBB1072 Package; 6481E2CC and DFBB1072 Dependency), the opposite
        # of the stored source-to-target waypoint order.
        TARGET_FIRST_TYPES = %w[NoteLink Package Dependency].freeze

        def direct?(connector)
          style = connector.style || {}
          style.key?(:direct) || style.key?("direct") ||
            TARGET_FIRST_TYPES.include?(connector.connector_type)
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
          BridgeSpans.new(crossings, first, last).to_a.sort_by { |bridge| distance(bridge.start, first) }
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

        def crossing(first, last, start, finish)
          SegmentGeometry.crossing(first, last, start, finish, RADIUS)
        end

        def distance(point, other)
          SegmentGeometry.distance(point, other)
        end

        def arc_commands(first, last, bridge)
          arc = "A #{radii(first, last, bridge)} 180 0 0 #{coordinates(bridge.finish)}"
          commands = ["L #{coordinates(bridge.start)}", arc]
          return commands unless bridge.leftover

          commands + ["L #{coordinates(bridge.finish)}", "A #{RADIUS} #{RADIUS} 0 1 0 #{coordinates(bridge.finish)}"]
        end

        # An axis-aligned arc has half its chord length as the radius along
        # the carrier and RADIUS across it; slanted chords keep the circle.
        def radii(first, last, bridge)
          axis = SegmentGeometry.axis_for(first, last)
          return "#{RADIUS} #{RADIUS}" unless axis

          half = Canvas.coord(SegmentGeometry.distance(bridge.start, bridge.finish) / 2.0)
          axis.zero? ? "#{half} #{RADIUS}" : "#{RADIUS} #{half}"
        end

        def coordinates(point)
          point.map { |value| Canvas.coord(value) }.join(" ")
        end
      end

      # The arc chords decorating one carrier segment, from its crossings.
      #
      # Partners crossing at one point share a single arc (0BE81AC5 draws one
      # arc for three coincident verticals).
      #
      # Axis-aligned carrier: crossings within NEAR_COINCIDENT pixels merge
      # into one arc spanning the outer chord ends (30D62231 draws one
      # 14-long arc over three horizontals one pixel apart; wider overlaps
      # have no corpus case and stay suppressed).
      #
      # Slanted carrier: distinct crossings whose spans overlap are all
      # suppressed so route order cannot select one of several ambiguous
      # arcs. Empirical fit, 0BE81AC5 (the only slanted carrier with three
      # coincident partners in the corpus): EA also writes one zero-length
      # arc after the chord. Fewer coincident partners are not evidenced.
      class BridgeSpans
        def initialize(crossings, first, last)
          @first = first
          @axis = SegmentGeometry.dominant_axis(first, last)
          @aligned = !SegmentGeometry.axis_for(first, last).nil?
          groups = crossings.group_by { |point| point.map { |value| value.round(6) } }.values
          @bridges = groups.map { |group| bridge_at(group, last) }
        end

        def to_a
          @aligned ? merged : @bridges.reject.with_index { |_bridge, index| overlapping?(index) }
        end

        private

        def bridge_at(group, last)
          start, finish = SegmentGeometry.chord(@first, last, group.first, ConnectorBridges::RADIUS)
          leftover = !@aligned && group.size >= ConnectorBridges::COINCIDENT_LEFTOVER
          ConnectorBridges::Bridge.new(start, finish, leftover)
        end

        def merged
          ordered = @bridges.sort_by { |bridge| distance(bridge.start) }
          components = ordered.slice_when { |one, other| !overlap?(one, other) }
          components.filter_map { |component| component.one? ? component.first : merge(component) }
        end

        def merge(component)
          return if spread(component) > ConnectorBridges::NEAR_COINCIDENT

          finish = component.map(&:finish).max_by { |point| distance(point) }
          ConnectorBridges::Bridge.new(component.first.start, finish, false)
        end

        def spread(component)
          centres = component.map { |bridge| bridge.start[@axis] + bridge.finish[@axis] }
          (centres.max - centres.min) / 2.0
        end

        def overlapping?(index)
          @bridges.each_with_index.any? do |other, other_index|
            index != other_index && overlap?(@bridges[index], other)
          end
        end

        def overlap?(one, other)
          minimum, maximum = [one.start[@axis], one.finish[@axis]].minmax
          other_minimum, other_maximum = [other.start[@axis], other.finish[@axis]].minmax
          minimum < other_maximum && other_minimum < maximum
        end

        def distance(point)
          SegmentGeometry.distance(point, @first)
        end
      end
    end
  end
end
