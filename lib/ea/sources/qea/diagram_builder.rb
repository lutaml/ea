# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Translates EA t_diagram + t_diagramlinks + t_diagramobjects
      # into Ea::Model::Diagram with placed DiagramElements and
      # DiagramConnectors (including pixel coordinates and parsed
      # styles).
      class DiagramBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all
          diagrams = database.collections[:diagrams] || []
          diagrams.map { |row| build_one(row) }
        end

        def build_one(diagram_row)
          Ea::Model::Diagram.new(
            id: IdNormalizer.from_guid(diagram_row.ea_guid),
            name: diagram_row.name,
            package_id: package_id_for(diagram_row),
            diagram_type: diagram_row.diagram_type,
            bounds: bounds_for(diagram_row),
            elements: build_elements(diagram_row),
            connectors: build_connectors(diagram_row),
            annotations: AnnotationBuilder.from_note(diagram_row.notes,
                                                     diagram_row.ea_guid,
                                                     kind: "documentation")
          )
        end

        private

        def build_elements(diagram_row)
          objs = database.diagram_objects_for(diagram_row.diagram_id) || []
          objs.map { |obj_row| build_element(obj_row, diagram_row) }
        end

        def build_element(obj_row, diagram_row)
          Ea::Model::DiagramElement.new(
            id: IdNormalizer.synthetic("de", diagram_row.diagram_id,
                                       obj_row.instance_id),
            diagram_id: IdNormalizer.from_guid(diagram_row.ea_guid),
            model_element_ref: ref_for_object(obj_row),
            bounds: bounds_from_rect(obj_row),
            style: DiagramStyleParser.parse(obj_row.objectstyle)
          )
        end

        def build_connectors(diagram_row)
          links = database.diagram_links_for(diagram_row.diagram_id) || []
          links.map { |link_row| build_connector(link_row, diagram_row) }
        end

        def build_connector(link_row, diagram_row)
          Ea::Model::DiagramConnector.new(
            id: IdNormalizer.synthetic("dc", diagram_row.diagram_id,
                                       link_row.instance_id),
            diagram_id: IdNormalizer.from_guid(diagram_row.ea_guid),
            relationship_ref: ref_for_connector(link_row),
            waypoints: waypoints_for_link(link_row, diagram_row),
            style: DiagramStyleParser.parse(link_row.style)
          )
        end

        # EA's t_diagramlinks.Geometry field stores connector routing
        # in a packed format. The leading "X1,Y1,X2,Y2" pair (when
        # present) is in a coordinate frame that does NOT match the
        # element rect frame (elements use RectTop < RectBottom with
        # negative y; geometry uses positive y). Rather than trust
        # the stored absolute coords, we compute the polyline from
        # the actual placed-element bounds + the SX/SY/EX/EY delta
        # fields, which describe the bend routing relative to the
        # element edges.
        #
        # If we can't resolve the source or target element placement
        # for this diagram, we emit no waypoints (the connector will
        # be invisible) — better than drawing garbage lines.
        def waypoints_for_link(link_row, diagram_row)
          connector = database.find_connector(link_row.connectorid)
          return [] unless connector

          source_placement = diagram_object_placement(diagram_row.diagram_id,
                                                       connector.start_object_id)
          target_placement = diagram_object_placement(diagram_row.diagram_id,
                                                       connector.end_object_id)
          return [] unless source_placement && target_placement

          geom = parse_geometry_fields(link_row.geometry)
          edge_out = geom[:edge] || 0

          source_point = element_edge_point(source_placement, :source, edge_out)
          target_point = element_edge_point(target_placement, :target, edge_out)
          points = [source_point]
          # SX/SY: delta from source point to first bend.
          if geom[:sx] && geom[:sy] && (geom[:sx].nonzero? || geom[:sy].nonzero?)
            points << [source_point[0] + geom[:sx], source_point[1] + geom[:sy]]
          end
          # EX/EY: delta from second bend to target point. Reverse
          # to get from target back to the bend.
          if geom[:ex] && geom[:ey] && (geom[:ex].nonzero? || geom[:ey].nonzero?)
            points << [target_point[0] - geom[:ex], target_point[1] - geom[:ey]]
          end
          points << target_point

          points.map do |x, y|
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
          end
        end

        # Parse the SX, SY, EX, EY, EDGE key=value pairs out of the
        # geometry string. Each is `KEY=<int>;`. We deliberately do
        # NOT extract the leading X1,Y1,X2,Y2 numbers because those
        # are in a different coordinate frame (see note above).
        def parse_geometry_fields(geometry)
          return {} if geometry.nil? || geometry.empty?

          s = geometry.to_s
          {
            sx: pick_int(s, /SX=(-?\d+)/),
            sy: pick_int(s, /SY=(-?\d+)/),
            ex: pick_int(s, /EX=(-?\d+)/),
            ey: pick_int(s, /EY=(-?\d+)/),
            edge: pick_int(s, /EDGE=(-?\d+)/)
          }
        end

        def pick_int(str, pattern)
          match = str.match(pattern)
          return nil unless match

          Integer(match[1])
        rescue ArgumentError
          nil
        end

        # Find where a given EA object is placed on this diagram.
        def diagram_object_placement(diagram_id, ea_object_id)
          objects = database.diagram_objects_for(diagram_id) || []
          objects.find { |o| o.ea_object_id == ea_object_id }
        end

        # Compute the connection point on an element's edge for the
        # given side. EA's `EDGE` field on t_diagramlinks tells us
        # which edge the connector attaches to:
        #   1 = top (source), 2 = right, 3 = bottom, 4 = left,
        #   plus 5/6/7/8 for diagonals (treated as the cardinal here).
        # We use the center of the chosen edge as the connection point.
        def element_edge_point(placement, end_kind, edge_code)
          b = bounds_from_rect(placement)
          case effective_edge(edge_code, end_kind)
          when :top    then [b.x + b.width / 2, b.y]
          when :right  then [b.x + b.width, b.y + b.height / 2]
          when :bottom then [b.x + b.width / 2, b.y + b.height]
          when :left   then [b.x, b.y + b.height / 2]
          else              [b.x + b.width / 2, b.y + b.height / 2]
          end
        end

        def effective_edge(edge_code, end_kind)
          mapping = {
            1 => :top, 2 => :right, 3 => :bottom, 4 => :left,
            5 => :top, 6 => :right, 7 => :bottom, 8 => :left
          }
          mapping[edge_code.to_i] || :center
        end

        def package_id_for(diagram_row)
          pkg = database.find_package(diagram_row.package_id)
          return nil unless pkg

          IdNormalizer.from_guid(pkg.ea_guid)
        end

        def bounds_for(diagram_row)
          Ea::Model::Bounds.new(
            x: 0,
            y: 0,
            width: diagram_row.cx || 0,
            height: diagram_row.cy || 0
          )
        end

        def bounds_from_rect(obj_row)
          Ea::Model::Bounds.new(
            x: obj_row.rectleft || 0,
            y: obj_row.recttop || 0,
            width: (obj_row.rectright || 0) - (obj_row.rectleft || 0),
            height: (obj_row.rectbottom || 0) - (obj_row.recttop || 0)
          )
        end

        def ref_for_object(obj_row)
          obj = database.find_object(obj_row.ea_object_id)
          return nil unless obj

          IdNormalizer.from_guid(obj.ea_guid)
        end

        def ref_for_connector(link_row)
          conn = database.find_connector(link_row.connectorid)
          return nil unless conn

          IdNormalizer.from_guid(conn.ea_guid)
        end
      end
    end
  end
end
