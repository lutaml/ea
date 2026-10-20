# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Translates EA diagrams from the XMI source into Ea::Model
      # instances. Uses the rich placement data inside the
      # <xmi:Extension> block (Left/Top/Right/Bottom, BCol, font,
      # SOID/EOID, EDGE, label boxes) when present. Falls back to
      # the UML-DI owned_element bounds otherwise.
      class DiagramBuilder
        autoload :FontSettings, "ea/sources/xmi/diagram_builder/font_settings"
        autoload :UmldiEdges, "ea/sources/xmi/diagram_builder/umldi_edges"

        attr_reader :root, :xmi_path

        def initialize(root, xmi_path = nil)
          @root = root
          @xmi_path = xmi_path
        end

        def build_all
          ext_diagrams = extension_diagrams
          return [] if ext_diagrams.empty?

          ext_diagrams.map { |d| build_one(d) }
        end

        # The XMI stores diagrams in two places:
        # - root.model.diagram — UML-DI shape (often just one or none)
        # - root.extension.diagrams.diagram — the rich EA extension
        #   block with placement/style/connector data (the source of
        #   truth for rendering).
        # We use the extension block when present; fall back to UML-DI
        # otherwise.
        def extension_diagrams
          ext = root.extension
          return [] unless ext&.diagrams

          ext.diagrams.diagram.to_a
        end

        def build_one(ext_diagram)
          id = IdNormalizer.from_xmi_id(ext_diagram.id)
          ext_elements = ExtensionElements.new(ext_diagram)
          placed_elements = ext_elements.placed_elements
          placed_connectors = ext_elements.placed_connectors
          props = ext_diagram.properties
          umldi_keywords = keywords_for(id)

          Ea::Model::Diagram.new(
            id: id,
            name: props&.name || ext_diagram.id,
            package_id: ext_diagram.model&.package,
            diagram_type: props&.type&.split(":")&.last&.downcase,
            bounds: page_bounds(ext_diagram),
            style: style_for(ext_diagram),
            style_ex: style_ex_for(ext_diagram),
            show_notes: style_ex_for(ext_diagram).to_s.include?("ShowNotes=1"),
            show_package_contents: style_flag?(ext_diagram, "PackageContents"),
            show_foreign: style_flag?(ext_diagram, "HighlightForeign"),
            hand_draw: style_flag?(ext_diagram, "HandDraw"),
            elements: build_elements(placed_elements, id, umldi_keywords),
            connectors: build_connectors(placed_connectors,
                                          placed_elements, id),
            annotations: []
          )
        end

        # EA's XMI stores Style (a.k.a. Style1) in `style1.value` —
        # the per-diagram feature visibility flags (HideAtts, HideOps,
        # HideStereo, etc.). Parsed by DisplayConfig alongside
        # StyleEx.
        def style_for(ext_diagram)
          style1 = ext_diagram.style1
          return nil unless style1

          style1.value
        end

        # EA's XMI stores StyleEx in the diagram's `style2.value`
        # attribute (alongside Style1 in `style1.value`). The value
        # is a semicolon-separated key=value string carrying the
        # Theme=:NNN identifier and behavioral flags (SuppressFOC,
        # AttPkg, ShowNotes, etc.) — the same shape our Diagram
        # model expects in `style_ex`.
        def style_ex_for(ext_diagram)
          style2 = ext_diagram.style2
          return nil unless style2

          style2.value
        end

        private

        def style_flag?(ext_diagram, key)
          value = style_for(ext_diagram).to_s[/(?:\A|;)#{key}=(\d+)/, 1]
          value.to_i.nonzero? ? true : false
        end

        def page_bounds(ext_diagram)
          style = style_for(ext_diagram).to_s
          width = style[/(?:\A|;)DocSize\.cx=(\d+)/, 1]
          height = style[/(?:\A|;)DocSize\.cy=(\d+)/, 1]
          return nil unless width && height

          Ea::Model::Bounds.new(x: 0, y: 0, width: width.to_i, height: height.to_i)
        end

        def build_elements(placed, owner_id, umldi_keywords = {})
          placed.map { |p| build_element(p, owner_id, umldi_keywords) }
        end

        def build_element(placed, owner_id, umldi_keywords = {})
          geom = placed.geometry
          style = placed.style
          bounds = build_bounds(geom.left, geom.top, geom.right, geom.bottom)
          font = (@font_settings ||= FontSettings.new(xmi_path)).for(placed)
          Ea::Model::DiagramElement.new(
            id: IdNormalizer.synthetic_id(owner_id, "elem", placed.subject),
            diagram_id: owner_id,
            model_element_ref: placed.subject,
            bounds: bounds,
            image_bounds: (build_bounds(geom.img_left, geom.img_top, geom.img_right, geom.img_bottom) unless bounds),
            background_color: style.background_color,
            line_color: style.line_color,
            line_width: style.line_width,
            font_family: font[:family],
            font_size: font[:size],
            font_logical_height: font[:logical_height],
            font_size_inherited: ExtensionStyleParser.split_pairs(style.raw.to_s)["fontsz"] == "0",
            font_bold: style.bold,
            font_italic: style.italic,
            font_underline: style.underline,
            show_tagged_values: style.show_tagged_values,
            icon_visibility: style.hide_icon&.to_s,
            z_order: placed.seqno,
            duid: style.duid,
            umldi_keyword: umldi_keywords[placed.subject],
            style: {}
          )
        end

        def build_bounds(left, top, right, bottom)
          return nil unless left && top && right && bottom

          Ea::Model::Bounds.new(x: left, y: top,
                                 width: right - left,
                                 height: bottom - top)
        end

        def build_connectors(placed_connectors, placed_elements, owner_id)
          # Index elements by DUID so we can resolve SOID/EOID.
          by_duid = placed_elements.each_with_object({}) do |pe, acc|
            acc[pe.style.duid] = pe if pe.style.duid
          end
          by_subject = placed_elements.group_by { |pe| guid_key(pe.subject) }

          placed_connectors.each_with_index.map do |placed, index|
            build_connector(placed, by_duid, by_subject, owner_id, index)
          end
        end

        def build_connector(placed, by_duid, by_subject, owner_id, rank)
          geom = placed.geometry
          style = placed.style
          edge_source, edge_target = umldi_ends(owner_id, placed)
          source = by_duid[style.soid] || sole_placement(by_subject, edge_source)
          target = by_duid[style.eoid] || sole_placement(by_subject, edge_target)
          ext_meta = connector_meta(placed.subject)
          route = connector_route(placed, source, target, owner_id, ext_meta[:ea_type])
          Ea::Model::DiagramConnector.new(
            id: IdNormalizer.synthetic_id(owner_id, "conn", placed.subject),
            diagram_id: owner_id,
            relationship_ref: placed.subject,
            paint_order: [rank],
            source_duid: style.soid,
            target_duid: style.eoid,
            source_element_ref: source && synthetic_element_id(owner_id, source),
            target_element_ref: target && synthetic_element_id(owner_id, target),
            source_edge: geom.edge,
            target_edge: geom.edge,
            connector_type: ext_meta[:ea_type],
            direction: ext_meta[:direction],
            waypoints: route[:waypoints],
            style: route[:style],
            line_color: style.color,
            line_width: style.line_width,
            hidden: style.hidden,
            label_boxes: serialize_label_boxes(geom.label_boxes)
          )
        end

        def connector_meta(subject_id)
          connector = connector_index[subject_id]
          return { ea_type: nil, direction: nil } unless connector

          props = connector.properties
          {
            ea_type: props&.ea_type,
            direction: props&.direction
          }
        end

        def connector_index
          @connector_index ||= begin
            conns = root.extension&.connectors&.connector || []
            conns.each_with_object({}) do |c, acc|
              acc[c.idref] = c if c.idref
            end
          end
        end

        def umldi_extractor
          return nil unless xmi_path

          @umldi_extractor ||= UmldiKeywordExtractor.new(xmi_path)
        end

        def keywords_for(diagram_id)
          return {} unless umldi_extractor

          umldi_extractor.keywords_for_diagram(diagram_id)
        end

        def synthetic_element_id(owner_id, placed)
          IdNormalizer.synthetic_id(owner_id, "elem", placed.subject)
        end

        def connector_route(placed, source, target, owner_id, type)
          native = umldi_waypoints(owner_id, placed) if placed.geometry.bend_points.to_a.empty?
          points = native || compute_waypoints(placed.geometry, source, target,
                                               style: placed.style, connector_type: type)
          native ||= umldi_waypoints(owner_id, placed) if points.empty?
          { waypoints: native || points, style: native ? { umldi_route: true } : {} }
        end

        # EA's unique exported edge supplies bendless routes and recovers
        # routes whose placement endpoints cannot be resolved.
        def umldi_waypoints(diagram_id, placed)
          return unless xmi_path

          route = umldi_edges.route_for(diagram_id, placed.subject)
          route&.map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) }
        end

        def umldi_ends(diagram_id, placed)
          return unless xmi_path

          umldi_edges.ends_for(diagram_id, placed.subject)
        end

        def sole_placement(by_subject, subject)
          placements = by_subject[guid_key(subject)]
          placements.first if placements&.one?
        end

        # EA spells one GUID with an EAID_ or EAPK_ prefix and mixed case
        # depending on the element kind.
        def guid_key(subject)
          subject&.sub(/\AEA(?:ID|PK)_/, "")&.upcase
        end

        def umldi_edges
          @umldi_edges ||= UmldiEdges.new(xmi_path)
        end

        def compute_waypoints(geom, source, target, style:, connector_type:)
          src_bounds = bounds_from_placed(source)
          tgt_bounds = bounds_from_placed(target)
          return [] unless src_bounds && tgt_bounds

          stored = stored_route(geom, style, connector_type, src_bounds, tgt_bounds)
          return stored if stored

          router = Ea::Svg::ConnectorRouter.new(
            source_bounds: src_bounds,
            target_bounds: tgt_bounds,
            edge_code: geom.edge,
            source_delta: [geom.sx, geom.sy],
            target_delta: [geom.ex, geom.ey],
            bend_path: geom.bend_points || []
          )
          router.waypoints.map do |x, y|
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
          end
        end

        # Stored bends are routed by StoredRoute where a QEA rule claims
        # them; anything else keeps the generic router.
        def stored_route(geom, style, connector_type, src_bounds, tgt_bounds)
          offsets = { source: [geom.sx, geom.sy], target: [geom.ex, geom.ey] }
          points = StoredRoute.new.waypoints(
            link: StoredRoute::Link.new(style.raw, geom.path.to_s.tr("$", ";"), offset_geometry(geom)),
            connector_type: connector_type, source: src_bounds, target: tgt_bounds,
            bends: geom.bend_points.to_a, offsets: offsets, edge: geom.edge
          )
          return unless points

          points.map do |x, y|
            Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
          end
        end

        def offset_geometry(geom)
          { "SX" => geom.sx, "SY" => geom.sy, "EX" => geom.ex, "EY" => geom.ey }
            .filter_map { |key, value| "#{key}=#{value};" if value }.join
        end

        def bounds_from_placed(placed)
          return nil unless placed

          g = placed.geometry
          return nil unless g.left && g.top && g.right && g.bottom

          Ea::Model::Bounds.new(x: g.left, y: g.top,
                                 width: g.right - g.left,
                                 height: g.bottom - g.top)
        end

        def edge_point(placed, edge_code, _end_kind)
          return nil unless placed

          geom = placed.geometry
          left = geom.left
          top = geom.top
          right = geom.right
          bottom = geom.bottom
          return nil unless left && top && right && bottom

          case edge_code
          when 1 then [(left + right) / 2, top]      # top
          when 2 then [right, (top + bottom) / 2]    # right
          when 3 then [(left + right) / 2, bottom]   # bottom
          when 4 then [left, (top + bottom) / 2]     # left
          else [(left + right) / 2, (top + bottom) / 2]
          end
        end

        def serialize_label_boxes(label_boxes)
          return {} unless label_boxes

          label_boxes.transform_values do |box|
            {
              "ox" => box.ox, "oy" => box.oy,
              "cx" => box.cx, "cy" => box.cy,
              "hidden" => box.hidden,
              "bold" => box.bold,
              "italic" => box.italic,
              "underline" => box.underline,
              "color" => box.color,
              "alignment" => box.align,
              "direction" => box.direction,
              "rotation" => box.rotation
            }
          end
        end
      end
    end
  end
end
