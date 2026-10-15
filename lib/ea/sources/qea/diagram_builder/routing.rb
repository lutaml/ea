# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Internal geometry for choosing the facing edges of stored routes.
        module Routing
          private

          # Keep a vertical tree trunk whose bends still fit both boxes
          # and the open gap; the closest facing edges need not share its x.
          def preserve_stored_tree?(points, link_row, connector, src, tgt)
            return false unless connector.connector_type == "Aggregation" && points.size == 4

            style = DiagramStyleParser.parse(link_row.style)
            return false unless style[:tree] == "V" && style[:lwidth] == "2"

            tree_bends_fit?(points[1], points[-2], src, tgt)
          end

          def tree_bends_fit?(first, last, source, target)
            first[0] != last[0] && first[1] == last[1] &&
              within_vertical_gap?(first[1], source, target) &&
              within_horizontal_span?(first, source) && within_horizontal_span?(last, target)
          end

          def within_vertical_gap?(height, source, target)
            height < source.y - 1 && height > target.y + target.height + 1
          end

          def within_horizontal_span?(point, bounds)
            point[0].between?(bounds.x, bounds.x + bounds.width)
          end

          # Returns a replacement 2-point route between the closest
          # facing edges, or the original points when: the boxes overlap
          # on both axes, the current route already docks those edges,
          # or no aligned dock fits the edges' overlap range.
          def facing_edge_route(points, src, tgt)
            v_gap = v_dir = h_gap = h_dir = nil
            if src.y >= tgt.y + tgt.height
              v_gap = src.y - (tgt.y + tgt.height)
              v_dir = [:t, :b]
            elsif tgt.y >= src.y + src.height
              v_gap = tgt.y - (src.y + src.height)
              v_dir = [:b, :t]
            end
            if src.x >= tgt.x + tgt.width
              h_gap = src.x - (tgt.x + tgt.width)
              h_dir = [:l, :r]
            elsif tgt.x >= src.x + src.width
              h_gap = tgt.x - (tgt.x + tgt.width)
              h_dir = [:r, :l]
            end
            return points if v_gap.nil? && h_gap.nil?

            if !v_gap.nil? && (h_gap.nil? || v_gap <= h_gap)
              src_edge, tgt_edge = v_dir
            else
              src_edge, tgt_edge = h_dir
            end
            return points if docks_edges?(points, src, src_edge, tgt, tgt_edge)

            if %i[t b].include?(src_edge)
              lo = [src.x, tgt.x].max
              hi = [src.x + src.width, tgt.x + tgt.width].min
              return points if lo > hi

              x = points.first[0].clamp(lo, hi)
              [[x, src_edge == :t ? src.y : src.y + src.height],
               [x, tgt_edge == :t ? tgt.y : tgt.y + tgt.height]]
            else
              lo = [src.y, tgt.y].max
              hi = [src.y + src.height, tgt.y + tgt.height].min
              return points if lo > hi

              y = points.first[1].clamp(lo, hi)
              [[src_edge == :l ? src.x : src.x + src.width, y],
               [tgt_edge == :l ? tgt.x : tgt.x + tgt.width, y]]
            end
          end

          def docks_edges?(points, src, src_edge, tgt, tgt_edge)
            on_edge?(points.first, src, src_edge) && on_edge?(points.last, tgt, tgt_edge)
          end

          def on_edge?(pt, b, edge, tol = 2)
            x, y = pt
            case edge
            when :l then (x - b.x).abs <= tol && y.between?(b.y - tol, b.y + b.height + tol)
            when :r then (x - (b.x + b.width)).abs <= tol && y.between?(b.y - tol, b.y + b.height + tol)
            when :t then (y - b.y).abs <= tol && x.between?(b.x - tol, b.x + b.width + tol)
            else (y - (b.y + b.height)).abs <= tol && x.between?(b.x - tol, b.x + b.width + tol)
            end
          end
        end
      end
    end
  end
end
