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
        autoload :ConnectorMetadata, "ea/sources/xmi/diagram_builder/connector_metadata"
        autoload :AssociationClassMetadata, "ea/sources/xmi/diagram_builder/association_class_metadata"
        autoload :FontSettings, "ea/sources/xmi/diagram_builder/font_settings"
        autoload :StereotypeProfiles, "ea/sources/xmi/diagram_builder/stereotype_profiles"
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
          ext_elements = ExtensionElements.new(ext_diagram, connector_subjects: connector_index)
          placed_elements = ext_elements.placed_elements
          placed_connectors = ext_elements.placed_connectors
          props = ext_diagram.properties
          umldi_keywords = keywords_for(id)
          context = context_diagram?(ext_diagram)

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
            show_parents: !style_flag?(ext_diagram, "HideParents"),
            hand_draw: style_flag?(ext_diagram, "HandDraw"),
            elements: build_elements(placed_elements, id, umldi_keywords),
            connectors: build_connectors(placed_connectors, placed_elements, id, context),
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

        def context_diagram?(ext_diagram)
          name = ext_diagram.properties&.name.to_s
          return true if name.match?(/\AContext Diagram: Package (Clients|Suppliers) of /i)

          style_ex_for(ext_diagram).to_s.match(/(?:\A|;)SuppressFOC=(\d)/)&.public_send(:[], 1) != "1"
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
            font_size_unit: "pt",
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
            style: element_style(placed.subject)
          )
        end

        # XMI preserves UML member order in ownedAttribute. Carry that
        # provenance to the renderer so it does not replace it with a name sort.
        def element_style(subject)
          style = (@stereotype_profiles ||= StereotypeProfiles.new(root)).for(subject)
          return style unless source_ordered_classifiers.include?(subject)

          style.merge(stored_attribute_order: true)
        end

        def source_ordered_classifiers
          @source_ordered_classifiers ||= begin
            ids = []
            visit = lambda do |element|
              ids << element.id if TypeClassifierMap.classifier_type?(element.type)
              element.packaged_element.to_a.each { |child| visit.call(child) }
              element.nested_classifier.to_a.each { |child| visit.call(child) }
            end
            root.model&.packaged_element.to_a.each { |element| visit.call(element) }
            ids
          end
        end

        def build_bounds(left, top, right, bottom)
          return nil unless left && top && right && bottom

          Ea::Model::Bounds.new(x: left, y: top,
                                 width: right - left,
                                 height: bottom - top)
        end

        def build_connectors(placed_connectors, placed_elements, owner_id, context)
          # Index elements by DUID so we can resolve SOID/EOID.
          by_duid = placed_elements.each_with_object({}) do |pe, acc|
            acc[pe.style.duid] = pe if pe.style.duid
          end
          by_subject = placed_elements.group_by { |pe| guid_key(pe.subject) }

          placed_connectors.each_with_index.map do |placed, index|
            connector = build_connector(placed, by_duid, by_subject, owner_id, rank: index, context: context)
            mark_association_class(connector, placed, placed_elements, context)
          end
        end

        def mark_association_class(connector, placed, placed_elements, context)
          mark_plain_end_seats(connector, placed, context)
          reference = association_class_metadata.for(
            connector_index[placed.subject],
            placed_subjects: placed_elements.map(&:subject),
            waypoints: connector.waypoints
          )
          return connector unless reference

          connector.style[:association_class_ref] = reference
          connector.source_anchor = connector.waypoints.first.position
          connector
        end

        def mark_plain_end_seats(connector, placed, context)
          mark_plain_source_seat(connector, placed, context)
          mark_plain_target_seat(connector, placed, context)
        end

        def association_class_metadata
          @association_class_metadata ||= AssociationClassMetadata.new(xmi_path)
        end

        def build_connector(placed, by_duid, by_subject, owner_id, options)
          geom = placed.geometry
          style = placed.style
          edge_source, edge_target = connector_ends(owner_id, placed)
          source, target = placed_ends(style, by_duid, by_subject, edge_source, edge_target)
          ext_meta = connector_meta(placed.subject)
          route = connector_route(placed, source, target, owner_id, ext_meta[:ea_type])
          connector = Ea::Model::DiagramConnector.new(
            id: IdNormalizer.synthetic_id(owner_id, "conn", placed.subject),
            diagram_id: owner_id,
            relationship_ref: placed.subject,
            paint_order: [options.fetch(:rank)],
            source_duid: style.soid,
            target_duid: style.eoid,
            source_element_ref: source && synthetic_element_id(owner_id, source),
            target_element_ref: target && synthetic_element_id(owner_id, target),
            source_edge: geom.edge,
            target_edge: geom.edge,
            connector_type: ext_meta[:ea_type],
            direction: ext_meta[:direction],
            source_stereotype: ext_meta[:source_stereotype],
            target_stereotype: ext_meta[:target_stereotype],
            is_substitutable: ext_meta.fetch(:is_substitutable, false),
            waypoints: route[:waypoints],
            style: route[:style],
            line_color: style.color,
            line_width: style.line_width,
            hidden: style.hidden,
            label_boxes: serialize_label_boxes(geom.label_boxes)
          )
          connector.umldi_label_bounds = if options.fetch(:context)
                                           {}
                                         else
                                           umldi_label_bounds_for(owner_id, placed.subject,
                                                                  connector.label_boxes)
                                         end
          mark_stored_ray(connector, placed, source, target) unless options.fetch(:context)
          connector
        end

        def umldi_label_bounds_for(owner_id, connector_id, label_boxes)
          return {} unless xmi_path

          bounds = umldi_edges.label_bounds_for(owner_id, connector_id)
          return {} unless bounds

          bounds.reject do |key, _|
            extension_key = { source_role: :llt, source_multiplicity: :llb,
                              target_role: :lrt, target_multiplicity: :lrb }.fetch(key)
            label_boxes.key?(extension_key)
          end
        end

        def mark_stored_ray(connector, placed, source, target)
          return if connector.style[:umldi_route]

          metadata = stored_ray_metadata(connector, placed, source, target)
          metadata.each { |name, value| connector.public_send("#{name}=", value) }
          connector.style[:association_ray_outline] = true unless metadata.empty?
        end

        def stored_ray_metadata(connector, placed, source, target)
          geom = placed.geometry
          link = StoredRoute::Link.new(placed.style.raw, geom.path.to_s.tr("$", ";"))
          bounds = { source: bounds_from_placed(source), target: bounds_from_placed(target) }
          offsets = { source: [geom.sx, geom.sy], target: [geom.ex, geom.ey] }
          StoredRoute.new.ray_metadata(connector, link: link, bounds: bounds, offsets: offsets, edge: geom.edge)
        end

        def mark_plain_source_seat(connector, placed, context)
          return if context || !placed.geometry.path.to_s.empty? || connector.connector_type != "Aggregation"
          return unless connector.style.to_h.values_at(:mode, :lwidth, :tree) == ["3", "2", nil]
          return unless connector.source_stereotype.to_s.empty?

          connector.style[:plain_source_seat] = true
        end

        def mark_plain_target_seat(connector, placed, context)
          return if context || !placed.geometry.path.to_s.empty? || connector.connector_type != "Association"
          return unless connector.style.to_h.values_at(:mode, :lwidth, :tree) == ["3", "2", nil]
          return unless connector.target_stereotype.to_s.empty?

          connector.style[:plain_target_seat] = true
        end

        # The saved SOID/EOID can name the model connector's ends in reverse
        # order; the model connector decides which placement is the source.
        def placed_ends(style, by_duid, by_subject, edge_source, edge_target)
          source = by_duid[style.soid] || sole_placement(by_subject, edge_source)
          target = by_duid[style.eoid] || sole_placement(by_subject, edge_target)
          return [source, target] unless source && target &&
                                         reversed_ends?(source, target, edge_source, edge_target)

          [target, source]
        end

        def reversed_ends?(source, target, edge_source, edge_target)
          guid_key(edge_source) != guid_key(edge_target) &&
            guid_key(source.subject) == guid_key(edge_target) &&
            guid_key(target.subject) == guid_key(edge_source)
        end

        def connector_meta(subject_id)
          connector = connector_index[subject_id]
          return { ea_type: nil, direction: nil } unless connector

          props = connector.properties
          {
            ea_type: props&.ea_type,
            direction: props&.direction
          }.merge(connector_metadata.for(connector))
        end

        def connector_metadata
          @connector_metadata ||= ConnectorMetadata.new(xmi_path)
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
          { waypoints: native || points, style: connector_route_style(placed, native) }
        end

        def connector_route_style(placed, native)
          route_style = native ? { umldi_route: true } : {}
          # Label seats use EA's saved routing mode on every route source;
          # umldi_route still marks UMLDI waypoints as authoritative.
          route_style.merge!(Qea::DiagramStyleParser.parse(placed.style.raw).slice(:mode, :lwidth, :tree))
          # Source-known links without DUIDs use classifier endpoint metadata,
          # not a saved label box that might refer to the opposite end.
          route_style[:explicit_end_roles] = true unless placed.style.soid && placed.style.eoid
          route_style
        end

        # EA's unique exported edge supplies bendless routes and recovers
        # routes whose placement endpoints cannot be resolved.
        def umldi_waypoints(diagram_id, placed)
          return unless xmi_path

          route = umldi_edges.route_for(diagram_id, placed.subject)
          route&.map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) }
        end

        def connector_ends(diagram_id, placed)
          umldi_ends(diagram_id, placed) || extension_ends(placed.subject)
        end

        def extension_ends(subject)
          connector = connector_index[subject]
          [connector&.source&.idref, connector&.target&.idref]
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
