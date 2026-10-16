# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Orthogonal docking from the nearer physical intersection of a stored ray.
      module OrthogonalRay
        module_function

        def pairs_for(connector, source, target)
          return unless eligible?(connector, source, target)

          origins = [connector.source_anchor, connector.target_anchor]

          boxes = [source, target]
          physical = boxes.map { |box| outline(box) }
          clipped = physical_intersections(origins, physical)
          selected = nearer_origin(clipped, origins)
          orthogonal_pairs(clipped, selected, boxes, physical, origins) unless selected.nil?
        end

        def eligible?(connector, source, target)
          connector.style.to_h[:orthogonal_origin_ray] == true && source && target &&
            connector.source_anchor && connector.target_anchor
        end
        private_class_method :eligible?

        def physical_intersections(origins, physical)
          origins.each_with_index.map do |origin, index|
            ConnectorRedock.anchor_exit(origin, physical[index], origins[1 - index])
          end
        end
        private_class_method :physical_intersections

        def outline(box)
          Ea::Model::Bounds.new(x: box.x - 1, y: box.y - 1,
                                width: box.width + 2, height: box.height + 2)
        end
        private_class_method :outline

        def nearer_origin(clipped, origins)
          distances = clipped.zip(origins).map do |(x, y), origin|
            (x - origin.x)**2 + (y - origin.y)**2
          end
          distances.each_with_index.min.last unless distances.first == distances.last
        end
        private_class_method :nearer_origin

        def orthogonal_pairs(clipped, selected, boxes, physical, origins)
          point = clipped[selected]
          projected = project_opposite(point, physical[selected], boxes[1 - selected])
          return unless projected && forward_projection?(point, projected, origins, selected)

          selected.zero? ? [point, projected] : [projected, point]
        end
        private_class_method :orthogonal_pairs

        def project_opposite(point, own, other)
          case physical_edge_axis(point, own)
          when :horizontal then horizontal_projection(point, other)
          when :vertical then vertical_projection(point, other)
          end
        end
        private_class_method :project_opposite

        def physical_edge_axis(point, own)
          horizontal = [own.y, own.y + own.height].include?(point[1])
          vertical = [own.x, own.x + own.width].include?(point[0])
          return unless horizontal ^ vertical

          horizontal ? :horizontal : :vertical
        end
        private_class_method :physical_edge_axis

        def horizontal_projection(point, other)
          x, y = point
          return unless x.between?(other.x, other.x + other.width)

          edge = facing_edge(y, other.y, other.height)
          [x, edge] if edge
        end
        private_class_method :horizontal_projection

        def vertical_projection(point, other)
          x, y = point
          return unless y.between?(other.y, other.y + other.height)

          edge = facing_edge(x, other.x, other.width)
          [edge, y] if edge
        end
        private_class_method :vertical_projection

        def facing_edge(coordinate, start, extent)
          return start if coordinate < start
          return start + extent if coordinate > start + extent

          nil
        end
        private_class_method :facing_edge

        def forward_projection?(point, projected, origins, selected)
          first, last = origins.values_at(selected, 1 - selected)
          x, y = point
          target_x, target_y = projected
          ((last.x - first.x) * (target_x - x) + (last.y - first.y) * (target_y - y)).positive?
        end
        private_class_method :forward_projection?
      end
    end
  end
end
