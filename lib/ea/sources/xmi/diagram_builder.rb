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
            bounds: canvas_bounds(placed_elements),
            style: style_for(ext_diagram),
            style_ex: style_ex_for(ext_diagram),
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

        def canvas_bounds(placed_elements)
          return nil if placed_elements.empty?

          left = placed_elements.map { |e| e.geometry.img_left || e.geometry.left }.compact.min
          top = placed_elements.map { |e| e.geometry.img_top || e.geometry.top }.compact.min
          right = placed_elements.map { |e| e.geometry.img_right || e.geometry.right }.compact.max
          bottom = placed_elements.map { |e| e.geometry.img_bottom || e.geometry.bottom }.compact.max
          return nil unless left && top && right && bottom

          Ea::Model::Bounds.new(x: 0, y: 0,
                                 width: right - left,
                                 height: bottom - top)
        end

        def build_elements(placed, owner_id, umldi_keywords = {})
          placed.map { |p| build_element(p, owner_id, umldi_keywords) }
        end

        def build_element(placed, owner_id, umldi_keywords = {})
          geom = placed.geometry
          style = placed.style
          Ea::Model::DiagramElement.new(
            id: IdNormalizer.synthetic_id(owner_id, "elem", placed.subject),
            diagram_id: owner_id,
            model_element_ref: placed.subject,
            bounds: build_bounds(geom.left, geom.top, geom.right, geom.bottom),
            image_bounds: build_bounds(geom.img_left, geom.img_top, geom.img_right, geom.img_bottom),
            background_color: style.background_color,
            line_color: style.line_color,
            line_width: style.line_width,
            font_family: style.font_family,
            font_size: style.font_size,
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

          placed_connectors.map { |p| build_connector(p, by_duid, owner_id) }
        end

        def build_connector(placed, by_duid, owner_id)
          geom = placed.geometry
          style = placed.style
          source = by_duid[style.soid]
          target = by_duid[style.eoid]
          waypoints = compute_waypoints(geom, source, target)
          ext_meta = connector_meta(placed.subject)
          Ea::Model::DiagramConnector.new(
            id: IdNormalizer.synthetic_id(owner_id, "conn", placed.subject),
            diagram_id: owner_id,
            relationship_ref: placed.subject,
            source_duid: style.soid,
            target_duid: style.eoid,
            source_element_ref: source && synthetic_element_id(owner_id, source),
            target_element_ref: target && synthetic_element_id(owner_id, target),
            source_edge: geom.edge,
            target_edge: geom.edge,
            connector_type: ext_meta[:ea_type],
            direction: ext_meta[:direction],
            waypoints: waypoints,
            style: {},
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

        def compute_waypoints(geom, source, target)
          src_bounds = bounds_from_placed(source)
          tgt_bounds = bounds_from_placed(target)
          return [] unless src_bounds && tgt_bounds

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
              "cx" => box.cx, "cy" => box.cy,
              "ox" => box.ox, "oy" => box.oy,
              "bold" => box.bold,
              "italic" => box.italic,
              "underline" => box.underline,
              "align" => box.align
            }
          end
        end
      end
    end
  end
end
