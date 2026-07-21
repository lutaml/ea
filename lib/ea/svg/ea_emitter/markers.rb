# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits arrow / diamond markers per connector, matching EA's
      # convention:
      #   - Association (navigable): filled triangle at target
      #   - Generalization: open triangle at target
      #   - Realization: open triangle at target (path dashed)
      #   - Dependency: open arrow at target (path dashed)
      #   - Aggregation (source): open diamond at source
      #   - Composition (source): filled diamond at source
      class Markers
        ARROW_SIZE = 10

        attr_reader :diagram, :model_index, :canvas

        def initialize(diagram, model_index:, canvas: nil)
          @diagram = diagram
          @model_index = model_index
          @canvas = canvas
        end

        def render
          polys = visible_connectors.filter_map { |c| polygon_for(c) }
          return "" if polys.empty?

          polys.join("\n")
        end

        private

        def visible_connectors
          (diagram.connectors || []).reject(&:hidden)
        end

        def polygon_for(connector)
          relationship = relationship_for(connector)
          points = connector.waypoints.filter_map { |w| w.position && [w.position.x, w.position.y] }
          return nil if points.size < 2

          source = points.first
          target = points.last
          before_target = points[-2] || source

          marker = marker_for(relationship)
          return nil if marker == :none

          polygon = case marker
                    when :filled_triangle then filled_triangle(target, before_target)
                    when :open_triangle then open_triangle(target, before_target)
                    end
          return nil unless polygon

          style = polygon_style(relationship)
          %(<g style="#{style}">\n  #{polygon}\n</g>)
        end

        def marker_for(relationship)
          return :filled_triangle unless relationship

          case relationship
          when Ea::Model::Generalization, Ea::Model::Realization
            :open_triangle
          else
            :filled_triangle
          end
        end

        def polygon_style(relationship)
          case marker_for(relationship)
          when :open_triangle
            "stroke-width:2;stroke-linecap:round;stroke-linejoin:bevel; fill:#FFFFFF;fill-opacity:1.00; stroke:#000000; stroke-opacity:1.00"
          else
            "stroke-width:2;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:1.00"
          end
        end

        def filled_triangle(tip, base)
          polygon_points(tip, base, fill: true)
        end

        def open_triangle(tip, base)
          polygon_points(tip, base, fill: false)
        end

        def polygon_points(tip, base, fill:)
          tx, ty = translate_point(tip)
          bx, by = translate_point(base)
          dx = tx - bx
          dy = ty - by
          len = Math.sqrt(dx * dx + dy * dy)
          return nil if len.zero?

          ux = dx / len
          uy = dy / len
          back_x = tx - ux * ARROW_SIZE
          back_y = ty - uy * ARROW_SIZE
          perp_x = -uy * (ARROW_SIZE / 2.0)
          perp_y = ux * (ARROW_SIZE / 2.0)
          w1_x = back_x + perp_x
          w1_y = back_y + perp_y
          w2_x = back_x - perp_x
          w2_y = back_y - perp_y
          pts = "#{format('%.1f', tx)} #{format('%.1f', ty)} #{format('%.1f', w1_x)} #{format('%.1f', w1_y)} #{format('%.1f', w2_x)} #{format('%.1f', w2_y)}"
          %(<polygon points="#{pts}" shape-rendering="auto"   style="fill-rule:evenodd;"/>)
        end

        def translate_point(p)
          return p unless canvas

          [canvas.translate_x(p[0]), canvas.translate_y(p[1])]
        end

        def relationship_for(connector)
          return nil unless connector.relationship_ref

          model_index[connector.relationship_ref]
        end
      end
    end
  end
end
