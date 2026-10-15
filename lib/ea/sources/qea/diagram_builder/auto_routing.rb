# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Source-led routes for auto-routed associations with unequal end offsets.
        module AutoRouting
          private

          # Nonuniform horizontal offsets seat the route at the source row.
          # Uniform offsets retain the shared-overlap routing contract.
          def source_row_association_ray(model, link_row, diagram_row, geom, context)
            return model if context || !source_row_association?(model, link_row, geom)

            origins = source_row_origins(*stored_ray_boxes(link_row, diagram_row), geom)
            return model unless origins

            model.source_anchor, model.target_anchor = origins
            model.waypoints = origins.map { |point| Ea::Model::Waypoint.new(position: point) }
            model.style[:overlap_ray] = true
            model
          end

          def source_row_origins(source, target, geom)
            return nil unless source_row_faces_target?(source, target, geom[:edge])

            row = source_row_y(source, geom)
            return nil unless [source, target].all? { |box| within_height?(row, box) }

            [source, target].map { |box| Ea::Model::Point.new(x: box.x + box.width / 2.0, y: row) }
          end

          def source_row_y(source, geom)
            (source.y + source.height / 2.0 - geom[:sy]).floor
          end

          def source_row_faces_target?(source, target, edge)
            if edge == 2
              source.x + source.width < target.x
            else
              target.x + target.width < source.x
            end
          end

          def source_row_association?(model, link_row, geom)
            model.connector_type == "Association" && model.has_geometry_offsets &&
              model.source_anchor && model.target_anchor &&
              link_row.path.to_s.empty? && source_row_style?(model.style.to_h) &&
              source_row_offsets?(geom)
          end

          def source_row_style?(style)
            style[:mode] == "2" && style[:lwidth] == "2" && !style[:tree]
          end

          def source_row_offsets?(geom)
            geom.values_at(:sx, :sy, :ex, :ey).all? &&
              [2, 4].include?(geom[:edge]) && geom[:sy] != geom[:ey]
          end
        end
      end
    end
  end
end
