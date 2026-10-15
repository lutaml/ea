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
            return model if context || !stored_square_port_style?(model, link_row, geom)

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
