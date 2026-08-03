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
            style: diagram_row.pdata,
            style_ex: diagram_row.styleex,
            show_package_contents: package_contents_enabled?(diagram_row),
            hand_draw: hand_draw_enabled?(diagram_row),
            show_notes: show_notes_enabled?(diagram_row),
            show_parents: show_parents_enabled?(diagram_row),
            elements: build_elements(diagram_row),
            connectors: build_connectors(diagram_row),
            annotations: AnnotationBuilder.from_note(diagram_row.notes,
                                                     diagram_row.ea_guid,
                                                     kind: "documentation")
          )
        end

        # EA encodes "show package contents" as a non-zero integer in
        # t_diagram.ShowPackageContents (1 in basic.qea, 255 in
        # test.qea). When true, the package body lists its child
        # classifiers/sub-packages as "+ Name" rows.
        def package_contents_enabled?(diagram_row)
          return false if diagram_row.showpackagecontents.nil?

          diagram_row.showpackagecontents.to_i.nonzero?
        end

        # HandDraw=1 in t_diagram.StyleEx triggers EA's wavy
        # hand-drawn border style for every element on the diagram.
        def hand_draw_enabled?(diagram_row)
          style_ex = diagram_row.styleex.to_s
          match = style_ex.match(/HandDraw=(\d)/)
          match && match[1] == "1"
        end

        # ShowNotes=1 in t_diagram.StyleEx renders the classifier's
        # documentation note as wrapped text in the element body.
        def show_notes_enabled?(diagram_row)
          style_ex = diagram_row.styleex.to_s
          match = style_ex.match(/ShowNotes=(\d)/)
          match && match[1] == "1"
        end

        # HideParents=1 in t_diagram.PDATA suppresses EA's "off-canvas
        # parent class" ghost line — the italic parent name that EA
        # normally prepends to a placed element's header when its
        # generalization parent is not placed on the diagram.
        def show_parents_enabled?(diagram_row)
          pdata = diagram_row.pdata.to_s
          match = pdata.match(/HideParents=(\d)/)
          match ? match[1] != "1" : true
        end

        private

        def build_elements(diagram_row)
          objs = database.diagram_objects_for(diagram_row.diagram_id) || []
          objs.map { |obj_row| build_element(obj_row, diagram_row) }
        end

        def build_element(obj_row, diagram_row)
          style_hash = DiagramStyleParser.parse(obj_row.objectstyle)
          Ea::Model::DiagramElement.new(
            id: IdNormalizer.synthetic("de", diagram_row.diagram_id,
                                       obj_row.instance_id),
            diagram_id: IdNormalizer.from_guid(diagram_row.ea_guid),
            model_element_ref: ref_for_object(obj_row),
            bounds: bounds_from_rect(obj_row),
            style: style_hash,
            font_family: style_hash[:font],
            font_bold: truthy?(style_hash[:bold]),
            font_italic: truthy?(style_hash[:italic]),
            show_tagged_values: truthy?(style_hash[:tag])
          )
        end

        def truthy?(raw)
          raw == "1" || raw == "-1"
        end

        def build_connectors(diagram_row)
          links = database.diagram_links_for(diagram_row.diagram_id) || []
          explicit = links.map { |link_row| build_connector(link_row, diagram_row) }
          phantom = phantom_connectors(diagram_row, explicit)
          explicit + phantom
        end

        # EA renders PHANTOM CONNECTORS for associations that exist
        # in t_connector between two elements BOTH placed on the
        # current diagram, even when no t_diagramlinks entry exists
        # for that connector on this diagram. The phantom connector
        # renders as a straight line between the two element edges,
        # with SourceRole labels and appropriate markers.
        #
        # Only Association and Aggregation types produce phantom
        # connectors. Generalization, Dependency, and Package types
        # do NOT get phantom rendering.
        PHANTOM_CONNECTOR_TYPES = %w[Association Aggregation].freeze

        def phantom_connectors(diagram_row, explicit_connectors)
          placed_ids = placed_object_ids_on(diagram_row.diagram_id)
          explicit_conn_ids = explicit_connectors.map(&:relationship_ref).compact.to_set

          all_connectors = database.collections[:connectors] || []
          all_connectors.filter_map.with_index do |conn, idx|
            next nil unless PHANTOM_CONNECTOR_TYPES.include?(conn.connector_type)
            next nil unless placed_ids.include?(conn.start_object_id.to_i)
            next nil unless placed_ids.include?(conn.end_object_id.to_i)

            ref = ref_for_raw_connector(conn)
            next nil if explicit_conn_ids.include?(ref)

            build_phantom_connector(conn, diagram_row, idx)
          end
        end

        def ref_for_raw_connector(conn)
          IdNormalizer.from_guid(conn.ea_guid)
        end

        # Default label geometry for phantom connectors. EA renders
        # SourceRole + «property» + multiplicity at default offsets
        # from the source endpoint when no explicit geometry exists.
        DEFAULT_LABEL_BOXES = {
          llb: { "ox" => 0, "oy" => 0 },
          llt: { "ox" => 0, "oy" => 0 }
        }.freeze

        def build_phantom_connector(conn, diagram_row, idx)
          source_placement = diagram_object_placement(diagram_row.diagram_id,
                                                       conn.start_object_id)
          target_placement = diagram_object_placement(diagram_row.diagram_id,
                                                       conn.end_object_id)
          return nil unless source_placement && target_placement

          source_bounds = bounds_from_rect(source_placement)
          target_bounds = bounds_from_rect(target_placement)
          source_point = bounds_edge_point(source_bounds, target_bounds)
          target_point = bounds_edge_point(target_bounds, source_bounds)

          waypoints = [
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: source_point[0], y: source_point[1])),
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: target_point[0], y: target_point[1]))
          ]

          Ea::Model::DiagramConnector.new(
            id: IdNormalizer.synthetic("pc", diagram_row.diagram_id, idx),
            diagram_id: IdNormalizer.from_guid(diagram_row.ea_guid),
            relationship_ref: ref_for_raw_connector(conn),
            connector_type: conn.connector_type,
            direction: conn.direction,
            waypoints: waypoints,
            label_boxes: DEFAULT_LABEL_BOXES,
            style: {},
            hidden: false,
            has_geometry_offsets: false
          )
        end

        # Computes the edge attachment point on source bounds that
        # faces the target bounds. Uses the center-to-center direction
        # to pick the nearest edge intersection.
        def bounds_edge_point(bounds, other_bounds)
          cx = bounds.x + bounds.width / 2
          cy = bounds.y + bounds.height / 2
          ocx = other_bounds.x + other_bounds.width / 2
          ocy = other_bounds.y + other_bounds.height / 2

          dx = ocx - cx
          dy = ocy - cy

          if dx.abs * bounds.height > dy.abs * bounds.width
            x = dx > 0 ? bounds.x + bounds.width : bounds.x
            y = cy + dy * (x - cx).abs / dx.abs rescue cy
            [x, y]
          else
            y = dy > 0 ? bounds.y + bounds.height : bounds.y
            x = cx + dx * (y - cy).abs / dy.abs rescue cx
            [x, y]
          end
        end

        def build_connector(link_row, diagram_row)
          connector = database.find_connector(link_row.connectorid)
          geom = parse_geometry_fields(link_row.geometry)
          Ea::Model::DiagramConnector.new(
            id: IdNormalizer.synthetic("dc", diagram_row.diagram_id,
                                       link_row.instance_id),
            diagram_id: IdNormalizer.from_guid(diagram_row.ea_guid),
            relationship_ref: ref_for_connector(link_row),
            connector_type: connector&.connector_type,
            direction: connector&.direction,
            waypoints: waypoints_for_link(link_row, diagram_row),
            label_boxes: geom[:label_boxes] || {},
            style: DiagramStyleParser.parse(link_row.style),
            hidden: hidden?(link_row),
            ghost_labels: ghost_labels_for(connector, diagram_row, link_row),
            has_geometry_offsets: geometry_has_offsets?(link_row.geometry)
          )
        end

        # EA's t_diagramlinks.Geometry may carry explicit SX/SY/EX/EY
        # offset fields (even zeros) OR omit them entirely. The
        # presence of SX= gates the «import» package_anchor marker:
        # basic.qea Package Imports has SX=0;SY=0 → marker renders;
        # plateau Urban Planning ADE2 omits SX/SY → no marker.
        def geometry_has_offsets?(geometry_str)
          return false if geometry_str.nil? || geometry_str.empty?

          geometry_str.to_s.include?("SX=")
        end

        # EA's t_diagramlinks.Hidden is 1 when the user has hidden
        # the connector on this diagram (right-click → Hide). Hidden
        # connectors are absent from the reference SVG output.
        def hidden?(link_row)
          link_row.hidden.to_i.nonzero?
        end

        # Builds GhostLabel entries for connector endpoints that
        # reference objects NOT placed on the current diagram. EA
        # renders the off-canvas classifier's name as italic text
        # near the connector's on-canvas endpoint so the reader
        # knows what the connector attaches to outside the diagram.
        def ghost_labels_for(connector, diagram_row, link_row)
          return [] unless connector

          placed_ids = placed_object_ids_on(diagram_row.diagram_id)
          ghosts = []
          %i[source target].each do |end_kind|
            ea_object_id = end_kind == :source ? connector.start_object_id : connector.end_object_id
            next unless ea_object_id&.to_i&.positive?
            next if placed_ids.include?(ea_object_id.to_i)

            obj = database.find_object(ea_object_id.to_i)
            next unless obj
            next if obj.name.to_s.strip.empty?

            anchor_point = ghost_anchor(end_kind, connector, link_row, diagram_row)
            next unless anchor_point

            ghosts << Ea::Model::GhostLabel.new(
              id: IdNormalizer.synthetic("ghost", link_row.instance_id, ea_object_id.to_i),
              name: obj.name.to_s,
              end_kind: end_kind.to_s,
              anchor_x: anchor_point[0],
              anchor_y: anchor_point[1]
            )
          end
          ghosts
        end

        # Returns the Array of EA object IDs that have a placement
        # (t_diagramobjects row) on the given diagram.
        def placed_object_ids_on(diagram_id)
          objects = database.diagram_objects_for(diagram_id) || []
          objects.map(&:ea_object_id)
        end

        # Ghost label anchors at the on-canvas end of the connector.
        # When the source is off-canvas, anchor at the target's
        # first waypoint; vice versa for target off-canvas.
        def ghost_anchor(end_kind, connector, link_row, diagram_row)
          placement = if end_kind == :source
                        target_placement_for(connector, diagram_row)
                      else
                        source_placement_for(connector, diagram_row)
                      end
          return nil unless placement

          # Use the on-canvas end's edge center as the anchor.
          b = bounds_from_rect(placement)
          # Offset to the right of the element so the label sits
          # outside the on-canvas element. EA's actual offset is
          # roughly +12px in x and -8px in y from the element's
          # right-center edge.
          [b.x + b.width + 4, b.y + (b.height / 2) - 8]
        end

        def source_placement_for(connector, diagram_row)
          diagram_object_placement(diagram_row.diagram_id, connector.start_object_id)
        end

        def target_placement_for(connector, diagram_row)
          diagram_object_placement(diagram_row.diagram_id, connector.end_object_id)
        end

        # EA stores connector routing in two places:
        #
        #   - t_diagramlinks.Path: explicit intermediate waypoints as
        #     `x:y;x:y;...` in the element-rect coordinate frame.
        #     Present when the user has manually routed the connector
        #     or when EA's auto-router produced multi-bend paths.
        #   - t_diagramlinks.Geometry SX/SY/EX/EY: delta fields that
        #     describe the source-side and target-side bend offsets
        #     relative to the edge attachment points.
        #
        # Path takes precedence when present — it's the authoritative
        # routing. SX/SY/EX/EY are fallback for auto-routed direct
        # connectors with at most one bend on each end.
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

          intermediate = intermediate_waypoints(link_row)
          if intermediate.any?
            points = [source_point, *intermediate, target_point]
          else
            points = sx_sy_ex_ey_waypoints(source_point, target_point, geom)
          end

          points.map do |x, y|
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
          end
        end

        # Parse t_diagramlinks.Path into [[x, y], ...] intermediate
        # waypoints. Format: `x1:y1;x2:y2;...`. Empty string returns [].
        def intermediate_waypoints(link_row)
          raw = link_row.path.to_s
          return [] if raw.empty?

          raw.scan(/(-?\d+):(-?\d+)/).map { |x, y| [x.to_i, y.to_i] }
        end

        # Fallback when no explicit Path: compute source/target bend
        # points from the SX/SY/EX/EY delta fields.
        def sx_sy_ex_ey_waypoints(source_point, target_point, geom)
          points = [source_point]
          if geom[:sx] && geom[:sy] && (geom[:sx].nonzero? || geom[:sy].nonzero?)
            points << [source_point[0] + geom[:sx], source_point[1] + geom[:sy]]
          end
          if geom[:ex] && geom[:ey] && (geom[:ex].nonzero? || geom[:ey].nonzero?)
            points << [target_point[0] - geom[:ex], target_point[1] - geom[:ey]]
          end
          points << target_point
          points
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
            edge: pick_int(s, /EDGE=(-?\d+)/),
            label_boxes: parse_label_boxes(s)
          }
        end

        # Parse EA's $LLB=, $LLT=, $LRB=, $LRT= label box geometry.
        # Format: $LLB=CX=<int>:CY=<int>:OX=<int>:OY=<int>:HDN=0:BLD=0:
        #         ITA=0:UND=0:CLR=-1:ALN=0:DIR=0:ROT=0;
        # Only the FIRST segment carries the leading `$`; subsequent
        # segments use bare `KEY=` after the semicolon separator.
        #
        # Returns Hash keyed by :llb, :llt, :lrt, :lrb (and optional
        # :lmt, :lmb, :irhs, :ilhs). Each value is a Hash with:
        #   - "ox", "oy"         — label offset from anchor (always set)
        #   - "cx", "cy"         — cell size for label box
        #   - "hidden"           — bool, label suppressed when true
        #   - "bold", "italic", "underline" — bool font flags
        #   - "color"            — signed int (VB OLE_COLOR; -1 = default)
        #   - "alignment"        — 0=left, 1=center, 2=right
        #   - "direction"        — text direction enum
        #   - "rotation"         — degrees
        def parse_label_boxes(geom_str)
          boxes = {}
          %i[llb llt lrt lrb lmt lmb irhs ilhs].each do |key|
            match = geom_str.match(/(?:\$|;)\s*#{key.to_s.upcase}=([^;]*)/i)
            next unless match && !match[1].empty?

            parsed = parse_label_style(match[1])
            next unless parsed

            boxes[key] = parsed
          end
          boxes
        end
        public :parse_label_boxes

        # Parse one label box's colon-separated key=value body into
        # a Hash with string keys. Returns nil if OX/OY are absent.
        def parse_label_style(body)
          ox = body.match(/OX=(-?\d+)/)
          oy = body.match(/OY=(-?\d+)/)
          return nil unless ox && oy

          {
            "ox" => ox[1].to_i,
            "oy" => oy[1].to_i,
            "cx" => pick_int(body, /CX=(-?\d+)/),
            "cy" => pick_int(body, /CY=(-?\d+)/),
            "hidden" => pick_int(body, /HDN=(\d+)/) == 1,
            "bold" => pick_int(body, /BLD=(\d+)/) == 1,
            "italic" => pick_int(body, /ITA=(\d+)/) == 1,
            "underline" => pick_int(body, /UND=(\d+)/) == 1,
            "color" => pick_int(body, /CLR=(-?\d+)/),
            "alignment" => pick_int(body, /ALN=(\d+)/),
            "direction" => pick_int(body, /DIR=(\d+)/),
            "rotation" => pick_int(body, /ROT=(-?\d+)/)
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

        # EA's t_diagramobjects stores rect with the origin at the
        # bottom-left (math convention) — recttop > rectbottom for
        # valid bounds, and y values are often negative. Convert to
        # screen-space (origin top-left) by taking min/max and using
        # absolute width/height.
        def bounds_from_rect(obj_row)
          left = obj_row.rectleft || 0
          right = obj_row.rectright || 0
          top = obj_row.recttop || 0
          bottom = obj_row.rectbottom || 0
          Ea::Model::Bounds.new(
            x: [left, right].min,
            y: [top, bottom].min,
            width: (right - left).abs,
            height: (bottom - top).abs
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
