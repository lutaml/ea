# frozen_string_literal: true

module Ea
  module Svg
    # Computes connector waypoints using position-based orthogonal
    # routing. Given source and target element placements (their
    # image bounds), computes a 2- or 3-point polyline that
    # visually connects the correct edges.
    #
    # Algorithm:
    # 1. Determine the primary direction from source to target
    #    (left, right, up, down).
    # 2. Pick the source attachment edge + point based on direction.
    # 3. Pick the target attachment edge + point based on direction.
    # 4. Route orthogonally: straight line if aligned, else L-shape
    #    with one bend at the intersection of source x and target y
    #    (or vice versa).
    class ConnectorRouter
      attr_reader :source_bounds, :target_bounds, :edge_code

      def initialize(source_bounds:, target_bounds:, edge_code: nil)
        @source_bounds = source_bounds
        @target_bounds = target_bounds
        @edge_code = edge_code
      end

      def waypoints
        src_pt = source_point
        tgt_pt = target_point
        return [] unless src_pt && tgt_pt

        points = [src_pt]
        bend = bend_point(src_pt, tgt_pt)
        points << bend if bend
        points << tgt_pt
        points
      end

      private

      def source_point
        return nil unless source_bounds
        return edge_point(source_bounds, @edge_code) if @edge_code && @edge_code != 0

        # Auto-detect based on relative position
        primary_edge(source_bounds, target_bounds)
      end

      def target_point
        return nil unless target_bounds
        return opposite_edge_point(source_bounds, target_bounds, @edge_code) if @edge_code && @edge_code != 0

        primary_edge(target_bounds, source_bounds)
      end

      def edge_point(bounds, code)
        case code
        when 1 then [center_x(bounds), bounds.y]                       # top
        when 2 then [bounds.x + bounds.width, center_y(bounds)]        # right
        when 3 then [center_x(bounds), bounds.y + bounds.height]      # bottom
        when 4 then [bounds.x, center_y(bounds)]                       # left
        else      [center_x(bounds), center_y(bounds)]                 # center
        end
      end

      # For the target, use the edge facing the source.
      def opposite_edge_point(source, target, code)
        case code
        when 1 then [center_x(target), target.y + target.height]      # source top → target bottom
        when 2 then [target.x, center_y(target)]                       # source right → target left
        when 3 then [center_x(target), target.y]                       # source bottom → target top
        when 4 then [target.x + target.width, center_y(target)]       # source left → target right
        else      [center_x(target), center_y(target)]
        end
      end

      # Pick the edge of `bounds` that faces `other`.
      def primary_edge(bounds, other)
        return nil unless bounds && other

        dx = center_x(bounds) - center_x(other)
        dy = center_y(bounds) - center_y(other)

        if dx.abs > dy.abs
          # Horizontal relationship
          dx.positive? ? [bounds.x, center_y(bounds)] : [bounds.x + bounds.width, center_y(bounds)]
        else
          # Vertical relationship
          dy.positive? ? [center_x(bounds), bounds.y] : [center_x(bounds), bounds.y + bounds.height]
        end
      end

      def bend_point(src, tgt)
        return nil if src == tgt
        return nil if src[0] == tgt[0] || src[1] == tgt[1] # aligned: no bend

        # L-shape: bend at intersection.
        # For horizontal exit: bend at (tgt_x, src_y).
        # For vertical exit: bend at (src_x, tgt_y).
        if horizontal_exit?
          [tgt[0], src[1]]
        else
          [src[0], tgt[1]]
        end
      end

      def horizontal_exit?
        return false unless source_bounds && @edge_code

        @edge_code == 2 || @edge_code == 4 # right or left
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
