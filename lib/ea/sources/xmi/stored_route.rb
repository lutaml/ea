# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Routes an XMI connector the way the QEA source does: the same
      # center-ray ports and the same QEA route helpers, over the same
      # inputs (link style, bends in `x:y;` form, connector type, endpoint
      # boxes). Returns nil where QEA would fall back to bare SX/SY deltas,
      # which the generic router keeps handling.
      class StoredRoute < Qea::DiagramBuilder
        Link = Struct.new(:style, :path, :geometry)
        Connector = Struct.new(:connector_type)

        def initialize
          super(nil)
        end

        def waypoints(link:, connector_type:, source:, target:, bends:, offsets:, edge: nil)
          connector = Connector.new(connector_type)
          ports = { source: port_for(source, offsets[:source]), target: port_for(target, offsets[:target]) }
          edge ||= 0
          points = initial_points(link, connector, source, target, bends, ports, edge)
          return unless points

          finish(points, link, connector, source, target, bends, ports, offsets, edge)
        end

        # Saved rays retain origins and computed boundary ports, matching QEA.
        def ray_metadata(model, link:, bounds:, offsets:, edge:)
          if model.connector_type == "Generalization"
            overlap = mode2_overlap_metadata(model, link, bounds, offsets, edge)
            return overlap unless overlap.empty?

            return generalization_ray_metadata(model, link, bounds, offsets, edge)
          end

          return {} unless direct_association_ray?(model, bounds, offsets)

          source, target = bounds.values_at(:source, :target)
          geom = ray_geometry(offsets, edge)
          return {} unless saved_association_ray?(model, link, source, target, geom)

          ray_points(source, target, offsets, geom)
        end

        def phantom_waypoints(source, target)
          [bounds_edge_point(source, target), bounds_edge_point(target, source)]
        end

        # Apply QEA's saved Association stages after the initial route, including
        # UMLDI fallback. A single stored corner and an empty-path stored ray
        # carry mathematical origins that the generic facing-edge route loses.
        def association_route(model, link:, bounds:, offsets:, edge:)
          ROUTE_STAGES.each do |stage|
            found = method(stage).call(model, link, bounds, offsets, edge)
            return found unless found.empty?
          end

          return {} unless stored_association_candidate?(model, bounds)

          candidate = association_model(model, bounds, offsets)
          initial = candidate.waypoints
          association_stored_ray(candidate, link, bounds, ray_geometry(offsets, edge), false)
          return {} if candidate.waypoints.equal?(initial)

          association_metadata(candidate)
        end

        private

        ROUTE_STAGES = %i[umldi_association_metadata shared_overlap_metadata
                          source_row_metadata partial_port_metadata].freeze

        # Overlap rules need both end boxes and every end offset.
        def ray_inputs?(bounds, offsets)
          bounds.values.all? && offsets.values.flatten.none?(&:nil?)
        end

        # A Mode 2 Generalization whose stored Path is a horizontal jog is EA's
        # auto-route: QEA replaces the stored bends with one vertical ray, and
        # the same QEA rule decides it here.
        def mode2_overlap_metadata(model, link, bounds, offsets, edge)
          return {} if link.path.to_s.empty? || !ray_inputs?(bounds, offsets)

          candidate = association_model(model, bounds, offsets)
          initial = candidate.waypoints
          mode2_overlap_ray(candidate, link, bounds, ray_geometry(offsets, edge), false)
          return {} if candidate.waypoints.equal?(initial)

          { waypoints: candidate.waypoints, source_anchor: candidate.source_anchor,
            target_anchor: candidate.target_anchor, has_geometry_offsets: true }
        end

        # A stored (non-UMLDI) Association through the shared overlap row takes
        # QEA's overlap origins and flush ports, decided by the same QEA rule.
        def shared_overlap_metadata(model, link, bounds, offsets, edge)
          return {} if model.style[:umldi_route] || !ray_inputs?(bounds, offsets)

          candidate = association_model(model, bounds, offsets)
          geom = ray_geometry(offsets, edge)
          association_stored_ray(candidate, link, bounds, geom, false) if association_ray_style?(model.style.to_h)
          overlap_ray_origins(candidate, link, bounds, geom, false)
          return {} unless candidate.style[:overlap_ray]

          association_metadata(candidate)
        end

        # A Mode 2 Association with unequal end offsets and no (or a stale) Path
        # rides the source row, as QEA's source_row_association_ray decides.
        def source_row_metadata(model, link, bounds, offsets, edge)
          return {} if model.style[:umldi_route] || !ray_inputs?(bounds, offsets)

          candidate = association_model(model, bounds, offsets)
          source_row_association_ray(candidate, link, bounds, ray_geometry(offsets, edge), false)
          return {} unless candidate.style[:overlap_ray]

          association_metadata(candidate)
        end

        def umldi_association_metadata(model, link, bounds, offsets, edge)
          overlap = umldi_overlap_metadata(model, link, bounds, offsets, edge)
          return overlap unless overlap.empty?

          umldi_stored_ray_metadata(model, link, bounds, offsets, edge)
        end

        # UMLDI owns the route and ports. Classify a thin saved ray only when
        # its origins pass the shared unstroked-box checks; XMI has no QEA
        # database from which to infer a wider element outline.
        def umldi_stored_ray_metadata(model, link, bounds, offsets, edge)
          return {} unless umldi_thin_ray_candidate?(model, bounds, offsets)

          candidate = association_model(model, bounds, offsets)
          return {} unless association_ray_candidate?(candidate, link)
          return {} unless association_ray_origins(*bounds.values_at(:source, :target),
                                                   ray_geometry(offsets, edge), "0")

          { style: model.style.to_h.merge(stored_association_ray: true, association_ray_outline: true) }
        end

        def umldi_thin_ray_candidate?(model, bounds, offsets)
          model.style[:umldi_route] && model.style[:lwidth] == "0" &&
            bounds.values.all? && offsets.values.flatten.none?(&:nil?)
        end

        # UMLDI owns the drawn route; retain QEA's overlap origins only for
        # interpreting the stored relative end labels against that route.
        def umldi_overlap_metadata(model, link, bounds, offsets, edge)
          return {} unless umldi_overlap_candidate?(model, bounds, offsets)

          candidate = association_model(model, bounds, offsets)
          geom = ray_geometry(offsets, edge)
          association_stored_ray(candidate, link, bounds, geom, false) if association_ray_style?(model.style.to_h)
          overlap_ray_origins(candidate, link, bounds, geom, false)
          return {} unless candidate.style[:overlap_ray]

          { source_anchor: candidate.source_anchor, target_anchor: candidate.target_anchor,
            has_geometry_offsets: true, style: candidate.style.to_h }
        end

        def umldi_overlap_candidate?(model, bounds, offsets)
          model.style.to_h.values_at(:umldi_route, :mode, :lwidth) == [true, "2", "0"] &&
            model.waypoints.size == 2 && bounds.values.all? && offsets.values.flatten.none?(&:nil?)
        end

        # A zero-offset end has no explicit port, but QEA still carries both
        # mathematical origins for the emitter's final boundary redocking.
        def partial_port_metadata(model, link, bounds, offsets, edge)
          return {} unless partial_port_candidate?(model, link, bounds, offsets)

          source, target = bounds.values_at(:source, :target)
          return {} unless saved_association_ray?(model, link, source, target, ray_geometry(offsets, edge))

          association_ends(bounds, offsets).merge(has_geometry_offsets: true)
        end

        def partial_port_candidate?(model, link, bounds, offsets)
          model.connector_type == "Aggregation" && !model.style[:umldi_route] && !link.path.to_s.empty? &&
            direct_association_ray?(model, bounds, offsets) &&
            offsets.values.count { |offset| offset.all?(&:zero?) } == 1
        end

        def stored_association_candidate?(model, bounds)
          model.connector_type == "Association" && bounds.values.all? &&
            association_ray_style?(model.style.to_h) && model.style[:lwidth] == "2"
        end

        def association_metadata(model)
          fields = %i[waypoints source_anchor target_anchor source_port target_port has_geometry_offsets]
          fields.to_h { |name| [name, model.public_send(name)] }.merge(
            style: model.style.to_h.reject { |key, _| key == :umldi_route }
          )
        end

        def association_model(model, bounds, offsets)
          Ea::Model::DiagramConnector.new(
            { connector_type: model.connector_type, style: model.style.to_h.dup, waypoints: model.waypoints,
              has_geometry_offsets: !offsets[:source][0].nil? }.merge(association_ends(bounds, offsets))
          )
        end

        def association_ends(bounds, offsets)
          %i[source target].each_with_object({}) do |kind, result|
            box = bounds.fetch(kind)
            offset = offsets.fetch(kind)
            port = port_for(box, offset)
            result["#{kind}_port".to_sym] = point_for(port) if port
            result["#{kind}_anchor".to_sym] = association_anchor(box, offset)
          end
        end

        def association_anchor(box, offset)
          Ea::Model::Point.new(x: box.x + box.width / 2 + offset[0].to_i,
                               y: box.y + box.height / 2 + offset[1].to_i)
        end

        # XMI has no QEA database from which to infer a wider element outline,
        # so the saved connector width stands. A border-aware variant changed no
        # connector in the PLATEAU census.
        def association_outline_width(model, _link, _bounds)
          model.style[:lwidth]
        end

        def stored_ray_boxes(_link, bounds)
          bounds.values_at(:source, :target)
        end

        def direct_association_ray?(model, bounds, offsets)
          %w[Association Aggregation].include?(model.connector_type) && model.waypoints.size == 2 &&
            model.style.to_h.values_at(:mode, :lwidth, :tree) == ["1", "2", nil] &&
            bounds.values.all? && offsets.values.flatten.none?(&:nil?)
        end

        # A direct Generalization clips its saved mathematical origins rather
        # than treating boundary ports as the origins of the final drawn ray.
        def generalization_ray_metadata(model, link, bounds, offsets, edge)
          geom = ray_geometry(offsets, edge)
          return {} unless generalization_ray_candidate?(model, link, bounds, offsets, geom)

          source, target = bounds.values_at(:source, :target)
          return {} unless stored_ray_gap?(source, target, model.style[:mode], edge)

          points = ray_points(source, target, offsets, geom)
          return {} if points.empty?

          points.merge(style: generalization_ray_style(model, points, source, target))
        end

        def generalization_ray_candidate?(model, link, bounds, offsets, geom)
          model.waypoints.size == 2 && stored_ray_style?(model.style, link) &&
            bounds.values.all? && offsets.values.flatten.none?(&:nil?) &&
            (!geom[:sy].zero? || !geom[:ey].zero?)
        end

        def generalization_ray_style(model, points, source, target)
          candidate = Ea::Model::DiagramConnector.new(
            connector_type: model.connector_type, style: model.style.to_h.dup,
            source_anchor: points[:source_anchor], target_anchor: points[:target_anchor]
          )
          return model.style.to_h unless centered_origin_ray?(candidate, source, target)

          flags = { centered_origin_ray: true }
          flags[:stored_origin_ray] = true if stored_origin_ray?(candidate, source, target)
          model.style.to_h.merge(flags)
        end

        def ray_geometry(offsets, edge)
          { sx: offsets[:source][0], sy: offsets[:source][1],
            ex: offsets[:target][0], ey: offsets[:target][1], edge: edge }
        end

        def saved_association_ray?(model, link, source, target, geom)
          (!geom[:sy].zero? || !geom[:ey].zero?) &&
            stored_ray_gap?(source, target, "1", geom[:edge]) &&
            stored_association_path?(model, link, source, target, geom)
        end

        def ray_points(source, target, offsets, geom)
          ports = [port_for(source, offsets[:source]), port_for(target, offsets[:target])]
          return {} unless ports.all?

          { source_port: point_for(ports.first), target_port: point_for(ports.last),
            source_anchor: stored_ray_origin(source, geom[:sx], geom[:sy]),
            target_anchor: stored_ray_origin(target, geom[:ex], geom[:ey]),
            has_geometry_offsets: true }
        end

        def point_for(pair)
          Ea::Model::Point.new(x: pair[0], y: pair[1])
        end

        # Placements here are already Ea::Model::Bounds.
        def bounds_from_rect(bounds)
          bounds
        end

        def ported?(offset)
          offset.none?(&:nil?) && offset.any?(&:nonzero?)
        end

        def port_for(box, offset)
          ray_port(box, offset) if ported?(offset)
        end

        def initial_points(link, connector, source, target, bends, ports, edge)
          src = ports[:source] || element_edge_point(source, :source, edge)
          tgt = ports[:target] || element_edge_point(target, :target, edge)
          if Qea::DiagramStyleParser.parse(link.style)[:mode] == "1"
            [src, tgt]
          elsif edge == 2 && ports.values.all? && !valid_tree_path?(bends, source)
            [src, [tgt[0], src[1]], tgt]
          elsif edge == 2 && bends.size == 1
            tree_points(source, target, bends.first)
          elsif bends.any?
            bent_points(src, bends, tgt, link, connector, source, target)
          elsif ports.values.any?
            [src, tgt]
          end
        end

        def tree_points(src, tgt, bend)
          target_y = tgt.y + tgt.height <= src.y ? tgt.y + tgt.height : tgt.y
          [[src.x + src.width, bend[1]], [bend[0], bend[1]], [bend[0], target_y]]
        end

        def bent_points(src, bends, tgt, link, connector, source, target)
          points = [src, *bends, tgt]
          if connector.connector_type == "Generalization"
            preserve_side_entry = authored_lateral_side_entry?(points, bends, link, source, target)
            redock_parent_above(points, link, source, target)
            points[-1] = [points[-1][0], points[1][1]] if preserve_side_entry
          end
          points
        end

        # A single LH tree bend can be the authored side-entry level itself.
        # Parent-above redocking normally moves a Generalization to the target
        # bottom, which destroys that horizontal leg and disagrees with QEA.
        def authored_lateral_side_entry?(points, bends, link, source, target)
          return false unless bends.one? && points.size == 3 && lateral_side_entry_style?(link) &&
                              target.y + target.height <= source.y

          level_on_target_side?(points[1], target)
        end

        def lateral_side_entry_style?(link)
          style = Qea::DiagramStyleParser.parse(link.style)
          style[:mode] == "3" && style[:tree] == "LH" && style[:lwidth] == "2"
        end

        def within_width?(x, bounds)
          x.between?(bounds.x, bounds.x + bounds.width)
        end

        def level_on_target_side?(bend, target)
          bend[1].between?(target.y, target.y + target.height) && !within_width?(bend[0], target)
        end

        def finish(points, link, connector, source, target, bends, ports, offsets, edge)
          tree_route = stored_tree_route(points, link, connector, source, target, ports)
          if tree_route
            points = tree_route
          elsif %w[Association Aggregation].include?(connector.connector_type) && edge != 2
            points = facing(points, link, connector, source, target, bends)
          end
          points = level_entry_route(points, link, connector, source, target) if bends.any? && !tree_route
          points = drop_zero_length_tree_segments(points, link)
          empty_path_ray(points, link, connector, source, target, bends, ports, offsets, edge)
        end

        # An empty Path has no authored corner to keep: a computed EDGE2 jog
        # between ports that face across a gap becomes the straight port line.
        def empty_path_ray(points, link, connector, source, target, bends, ports, offsets, edge)
          style = Qea::DiagramStyleParser.parse(link.style)
          return points unless %w[Generalization Aggregation].include?(connector.connector_type) &&
                               points.size == 3 && bends.empty? && edge == 2 && ports.values.all? &&
                               style[:mode] == "3" && style[:lwidth] == "2" && !style[:tree]
          return points unless ray_gap?(source, target, offsets)

          ports.values_at(:source, :target)
        end

        def ray_gap?(source, target, offsets)
          return false unless source.x + source.width < target.x

          [[source, offsets[:source]], [target, offsets[:target]]].all? do |box, (x, y)|
            within_height?(stored_ray_origin(box, x, y).y, source) &&
              within_height?(stored_ray_origin(box, x, y).y, target)
          end
        end

        def stored_tree_route(points, link, connector, source, target, ports)
          stored_square_route(link, connector, source, target) ||
            stored_stair_route(link, connector, source, target) ||
            stored_lateral_route(link, connector, source, target, ported: ports.values.all?) ||
            derived_lateral_route(link, connector, source, target) ||
            horizontal_tree_route(points, link, connector, source, target)
        end

        def facing(points, link, connector, source, target, bends)
          stored_tree = preserve_stored_tree?(points, link, connector, source, target)
          unless stored_tree || level_corner_route?(points, link, connector, source, target)
            points = facing_edge_route(points, source, target)
          end
          if connector.connector_type == "Aggregation" && bends.any? && points.size >= 4 &&
             (generalization_outline_offset(link, points.size) == 1 ||
              (stored_tree && flush_width_zero_tree?(link)))
            redock_parent_above(points, link, source, target, strict: true)
          end
          redock_vertical_tree_trunk(points, link, connector, source, target) if bends.any?
          points
        end

        # EA's SX/SY (EX/EY) point from the box center toward the port,
        # y up; the port is where that ray leaves the box.
        def ray_port(bounds, offset)
          dx = offset[0].to_f
          dy = -offset[1].to_f
          center_x = bounds.x + bounds.width / 2.0
          center_y = bounds.y + bounds.height / 2.0
          t = [ray_scale(dx, bounds.x, bounds.width, center_x),
               ray_scale(dy, bounds.y, bounds.height, center_y)].min
          [(center_x + t * dx).round, (center_y + t * dy).round]
        end

        def ray_scale(delta, origin, length, center)
          return Float::INFINITY if delta.zero?

          ((delta.positive? ? origin + length : origin) - center) / delta
        end
      end
    end
  end
end
