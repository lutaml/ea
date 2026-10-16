# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Restore a saved square axis when its target remains on the outline
        # but the source has moved beyond the saved endpoint into the gap.
        module StoredSquarePorts
          private

          def restore_stored_square_ports(model, link_row, diagram_row, geom, context)
            return model if context

            model = mark_orthogonal_origin_ray(model, link_row, diagram_row, geom)
            return model if model.style.to_h[:orthogonal_origin_ray] == true

            restore_global_square_ports(model, link_row, diagram_row, geom)
          end

          def restore_global_square_ports(model, link_row, diagram_row, geom)
            return model unless stored_square_port_style?(model, link_row, geom)

            connector = database.find_connector(link_row.connectorid)
            points = stored_square_port_coordinates(connector)
            boxes = stored_square_port_boxes(connector, diagram_row)
            return model unless points && boxes

            ends = reclip_stored_square_source(points, *boxes)
            return model unless ends

            model.source_anchor, model.target_anchor = ends
            model.waypoints = ends.map { |point| Ea::Model::Waypoint.new(position: point) }
            model
          end

          # A square route with no stored bends uses the original mathematical
          # ray to choose its orthogonal dock axis at render time.
          def mark_orthogonal_origin_ray(model, link_row, diagram_row, geom)
            return model unless orthogonal_origin_style?(model, link_row, geom)

            origins = orthogonal_math_origins(link_row, diagram_row, geom)
            return model unless origins

            model.source_anchor, model.target_anchor = origins
            model.waypoints = origins.map { |point| Ea::Model::Waypoint.new(position: point) }
            model.style = model.style.to_h.merge(orthogonal_origin_ray: true)
            model
          end

          def orthogonal_math_origins(link_row, diagram_row, geom)
            connector = database.find_connector(link_row.connectorid)
            boxes = stored_square_port_boxes(connector, diagram_row)
            return unless boxes && orthogonal_box_gap?(*boxes)

            offsets = [[geom[:sx], geom[:sy]], [geom[:ex], geom[:ey]]]
            origins = boxes.zip(offsets).map { |box, offset| stored_ray_origin(box, *offset) }
            origins if orthogonal_origins_inside?(origins, boxes)
          end

          def orthogonal_origins_inside?(origins, boxes)
            origins.zip(boxes).all? { |point, box| origin_inside_outline?(point, box) }
          end

          def orthogonal_origin_style?(model, link_row, geom)
            %w[Association Generalization].include?(model.connector_type) && link_row.path.to_s.empty? &&
              model.style.to_h.values_at(:mode, :tree, :lwidth) == %w[3 OS 2] &&
              %i[sx sy ex ey].all? { |key| !geom[key].nil? }
          end

          def orthogonal_box_gap?(source, target)
            [source, target].all? { |box| box.width.positive? && box.height.positive? } &&
              (horizontal_ray_gap?(source, target) ^ vertical_ray_gap?(source, target))
          end

          def origin_inside_outline?(point, box)
            point.x.between?(box.x - 1, box.x + box.width + 1) &&
              point.y.between?(box.y - 1, box.y + box.height + 1)
          end

          def stored_square_port_style?(model, link_row, geom)
            style = model.style.to_h
            model.connector_type == "Association" && link_row.path.to_s.empty? &&
              style.values_at(:mode, :tree, :lwidth) == %w[3 OS 2] &&
              geom.values_at(:edge, :sx, :sy, :ex, :ey) == [1, 0, 0, 0, 0]
          end

          def stored_square_port_coordinates(connector)
            return unless connector

            values = [connector.ptstartx, connector.ptstarty, connector.ptendx, connector.ptendy]
            return if values.any?(&:nil?)

            [[values[0], -values[1]], [values[2], -values[3]]]
          end

          def stored_square_port_boxes(connector, diagram_row)
            return unless connector

            placements = [source_placement_for(connector, diagram_row),
                          target_placement_for(connector, diagram_row)]
            placements.map { |placement| bounds_from_rect(placement) } if placements.all?
          end

          def reclip_stored_square_source(points, source, target)
            first, last = points
            return unless first[0] == last[0] && square_axis_inside_boxes?(first[0], source, target)

            return unless stored_square_source_in_gap?(points, source, target)

            [Ea::Model::Point.new(x: first[0], y: source.y),
             Ea::Model::Point.new(x: last[0], y: last[1])]
          end

          def stored_square_source_in_gap?(points, source, target)
            first, last = points
            target_edge = target.y + target.height + 1
            last[1] == target_edge && target_edge < first[1] && first[1] < source.y
          end

          def square_axis_inside_boxes?(axis, source, target)
            [source, target].all? do |box|
              box.width.positive? && box.height.positive? && axis.between?(box.x, box.x + box.width)
            end
          end
        end
      end
    end
  end
end
