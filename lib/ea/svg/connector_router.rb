# frozen_string_literal: true

module Ea
  module Svg
    class ConnectorRouter
      # Empirically determined offset EA adds to top-edge
      # attachment points: connector starts ~9 px below the
      # element's logical top edge (matches header height).
      EDGE_TOP_OFFSET = 9

      attr_reader :source_bounds, :target_bounds, :edge_code,
                  :source_delta, :target_delta, :bend_path

      def initialize(source_bounds:, target_bounds:,
                     edge_code: nil,
                     source_delta: [0, 0], target_delta: [0, 0],
                     bend_path: nil)
        @source_bounds = source_bounds
        @target_bounds = target_bounds
        @edge_code = edge_code
        @source_delta = source_delta
        @target_delta = target_delta
        @bend_path = bend_path || []
      end

      def waypoints
        src_pt = source_point
        tgt_pt = target_point
        return [] unless src_pt && tgt_pt

        # Path= values from EA are ABSOLUTE pixel positions on the
        # diagram canvas (verified against reference SVGs). Use them
        # as-is — do not offset by src_pt.
        return [src_pt, *bend_path, tgt_pt] if bend_path.any?

        points = [src_pt]
        bend = bend_point(src_pt, tgt_pt)
        points << bend if bend
        points << tgt_pt
        points
      end

      private

      def source_point
        return nil unless source_bounds
        pt = if @edge_code && @edge_code != 0
               edge_point(source_bounds, @edge_code)
             else
               primary_edge(source_bounds, target_bounds)
             end
        return nil unless pt

        offset_by_delta(pt, source_delta)
      end

      def target_point
        return nil unless target_bounds
        pt = if @edge_code && @edge_code != 0
               opposite_edge_point(source_bounds, target_bounds, @edge_code)
             else
               primary_edge(target_bounds, source_bounds)
             end
        return nil unless pt

        offset_by_delta(pt, target_delta)
      end

      def offset_by_delta(point, delta)
        return point if delta.nil?

        [point[0] + (delta[0] || 0), point[1] + (delta[1] || 0)]
      end

      def edge_point(bounds, code)
        case code
        when 1 then [center_x(bounds), bounds.y + EDGE_TOP_OFFSET]
        when 2 then [bounds.x + bounds.width, center_y(bounds)]
        when 3 then [center_x(bounds), bounds.y + bounds.height]
        when 4 then [bounds.x, center_y(bounds)]
        else      [center_x(bounds), center_y(bounds)]
        end
      end

      def opposite_edge_point(source, target, code)
        case code
        when 1 then [center_x(target), target.y + target.height]
        when 2 then [target.x, center_y(target)]
        when 3 then [center_x(target), target.y]
        when 4 then [target.x + target.width, center_y(target)]
        else      [center_x(target), center_y(target)]
        end
      end

      def primary_edge(bounds, other)
        return nil unless bounds && other

        dx = center_x(bounds) - center_x(other)
        dy = center_y(bounds) - center_y(other)

        if dx.abs > dy.abs
          dx.positive? ? [bounds.x, center_y(bounds)] : [bounds.x + bounds.width, center_y(bounds)]
        else
          dy.positive? ? [center_x(bounds), bounds.y] : [center_x(bounds), bounds.y + bounds.height]
        end
      end

      def bend_point(src, tgt)
        return nil if src == tgt
        return nil if src[0] == tgt[0] || src[1] == tgt[1]

        if horizontal_exit?
          [tgt[0], src[1]]
        else
          [src[0], tgt[1]]
        end
      end

      def horizontal_exit?
        return false unless source_bounds && @edge_code

        @edge_code == 2 || @edge_code == 4
      end

      def center_x(bounds)
        bounds.x + (bounds.width / 2.0)
      end

      def center_y(bounds)
        bounds.y + (bounds.height / 2.0)
      end
    end
  end
end
