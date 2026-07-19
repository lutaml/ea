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
            waypoints: parse_waypoints(link_row.geometry),
            style: DiagramStyleParser.parse(link_row.style)
          )
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

        # EA stores connector geometry as a packed string of x,y
        # pairs separated by semicolons and pipes. Conservative
        # parse: extract digit pairs, take first/last as endpoints.
        def parse_waypoints(geometry)
          return [] if geometry.nil? || geometry.empty?

          numbers = geometry.to_s.scan(/-?\d+/).map(&:to_i)
          return [] if numbers.size < 4

          numbers.each_slice(2).filter_map do |xy|
            next nil if xy.size < 2

            Ea::Model::Waypoint.new(
              position: Ea::Model::Point.new(x: xy[0], y: xy[1])
            )
          end
        end
      end
    end
  end
end
