# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Stored mathematical docking for auto-routed associations.
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

          # When the shared row misses the target, retain the physical ports
          # and let the emitter clip their ray before inserting the elbow.
          def auto_port_elbow(model, link_row, diagram_row, geom, context)
            return model if context || !auto_port_elbow_candidate?(model, link_row, geom)

            source, target = stored_ray_boxes(link_row, diagram_row)
            origins = [stored_ray_origin(source, geom[:sx], geom[:sy]),
                       stored_ray_origin(target, geom[:ex], geom[:ey])]
            return model unless auto_port_elbow_origins?(source, target, origins, geom)

            apply_auto_port_elbow(model, origins)
          end

          def apply_auto_port_elbow(model, origins)
            model.source_anchor, model.target_anchor = origins
            model.waypoints = origins.map { |point| Ea::Model::Waypoint.new(position: point) }
            model.style = model.style.to_h.merge(association_ray_outline: true, auto_port_elbow: true)
            model
          end

          def auto_port_elbow_candidate?(model, link_row, geom)
            auto_port_elbow_model?(model) && link_row.path.to_s.empty? &&
              source_row_style?(model.style.to_h) && uniform_overlap_offsets?(geom) && geom[:edge] == 4
          end

          def auto_port_elbow_model?(model)
            model.connector_type == "Association" && model.has_geometry_offsets &&
              model.source_anchor && model.target_anchor && model.waypoints.size == 2
          end

          def auto_port_elbow_origins?(source, target, origins, geom)
            return false if overlap_origins(source, target, geom)
            return false unless source_row_faces_target?(source, target, geom[:edge])
            return false unless origins.first.x == source.x - 1
            return false if within_height?(origins.first.y, target)
            return false unless crosses_target_horizontal_edge?(origins, target)

            [source, target].zip(origins).all? { |box, origin| inside_box?(origin, grown_bounds(box, 1)) }
          end

          def crosses_target_horizontal_edge?(origins, target)
            outline = grown_bounds(target, 1)
            edge = Ea::Model::Bounds.new(x: outline.x, width: outline.width, height: 0,
                                         y: origins.first.y < outline.y ? outline.y : outline.y + outline.height)
            segment_crosses_box?(*origins, edge)
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
