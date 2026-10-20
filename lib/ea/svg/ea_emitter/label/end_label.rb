# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Renders the role + «property» + multiplicity cluster at one
        # endpoint of a UML association connector.
        #
        # EA encodes end-labels in two geometry boxes per endpoint:
        #
        #   LLT/LRT - "label text" position (role name slot)
        #   LLB/LRB - "label box" position (multiplicity slot)
        #
        # Each box carries OX/OY offsets from the connector anchor.
        # The «property» stereotype renders one line below the role
        # name. EA records qualified role names ("pkg::role") for
        # cross-package associations but suppresses label rendering
        # for those — only simple role names render.
        class EndLabel
          PROPERTY_STEREOTYPE = "«Property»"
          SEAT_FONT_SIZE = 7
          SEAT_X_INSET = 3
          SEAT_STEREOTYPE_GAP = 12
          # EA keeps an upward property seat's left edge at diagram x >= 3;
          # the stereotype line moves with the role. Measured only for the
          # default Cambria 7pt boxed cluster.
          MIN_ROLE_X = 3

          attr_reader :canvas, :model_index, :document, :theme,
                      :font_family, :font_size, :font_unit,
                      :font_weight, :font_style

          def initialize(canvas:, model_index:, document:, theme:,
                         font_family:, font_size:, font_unit:,
                         font_weight: 400, font_style: "normal")
            @canvas = canvas
            @model_index = model_index
            @document = document
            @theme = theme
            @font_family = font_family
            @font_size = font_size
            @font_unit = font_unit
            @font_weight = font_weight
            @font_style = font_style
          end

          # Returns an Array of `<text>` SVG strings for one endpoint.
          #
          #   text_box   - LLT or LRT box geometry (role position)
          #   mult_box   - LLB or LRB box geometry (mult position)
          #   anchor     - [x, y] of the connector endpoint
          #   connector  - the DiagramConnector (for relationship lookup)
          #   end_kind   - :source or :target
          #   heading    - [dx, dy] of the first leg leaving the anchor
          #   source_bounds - effective drawn source outline, in anchor coordinates
          #   target_face - exact drawn target dock face when it leads the emitted leg
          #   bend       - first bend of a saved descending vertical stair
          #   stored_labels - the connector has stored label boxes at
          #                   either end; false keeps the opposite-end
          #                   fallback
          def texts(text_box:, mult_box:, anchor:, connector:, end_kind:,
                    tree: false, heading: nil, stored_labels: false, bend: nil, source_bounds: nil,
                    target_face: nil, umldi_bounds: {})
            from_property, role, mult = role_and_multiplicity(connector, end_kind)
            if role_empty?(role) && mult_empty?(mult)
              other_from_prop, other_role, other_mult = role_and_multiplicity(connector,
                                                              opposite(end_kind))
              if stored_labels || connector.style.to_h[:explicit_end_roles]
                return [] if role_empty?(other_role) && mult_empty?(other_mult)

                return own_stereotype_only(text_box, anchor, connector,
                                           end_kind)
              end

              role = other_role if role_empty?(role)
              mult ||= other_mult
              from_property ||= other_from_prop
            end
            agg = aggregation_kind_for(connector, end_kind)
            standalone = standalone_multiplicity(role, mult, aggregation: agg)
            return [] if role_empty?(role) && (standalone.nil? || standalone.empty?)

            text_pos = position_at(text_box, anchor)
            mult_pos = position_at(mult_box, anchor) || text_pos
            if tree && zero_offset?(text_box, mult_box)
              text_pos, mult_pos = tree_positions(end_kind, anchor, role,
                                                  text_pos, mult_pos)
              mult_pos = tree_left_multiplicity(end_kind, heading, anchor, mult_box, mult) || mult_pos
              text_pos = tree_left_property_role(connector, end_kind, heading, anchor, text_box, role) || text_pos
            elsif mult_box && stored_offsets_zero?(mult_box)
              # Start at the legacy default; measured directional seats
              # below replace it for default Cambria labels.
              mult_pos = [anchor[0] + 12, anchor[1] + 15]
            end
            # The end's stored stereotype renders verbatim («Type» on
            # 066E0FD1, «Property» on the Property ends); no line when
            # the end has none.
            stereo = connector_source_dest_stereotype(connector, end_kind)
            stereo = stereo.nil? || stereo.empty? ? nil : "«#{stereo}»"
            direction = leg_direction(end_kind, heading)
            if direction && !(tree && zero_offset?(text_box, mult_box))
              text_pos = plain_leftward_source_role(connector, direction, anchor, text_box, role) ||
                         plain_vertical_role(connector, direction, anchor, text_box, role) ||
                         source_property_seat(connector, direction, anchor, text_box, role) ||
                         plain_upward_seat(connector, direction, anchor, text_box, role) ||
                         role_seat(connector, direction, anchor, text_box, role) || text_pos
              mult_pos = directional_multiplicity(direction, anchor, mult_box, mult) ||
                         horizontal_tree_multiplicity(connector, direction, anchor, mult_box, mult) ||
                         mult_seat(direction, anchor, mult_box) || mult_pos
            elsif end_kind == :target && !(tree && zero_offset?(text_box, mult_box))
              text_pos = plain_leftward_target_role(connector, heading, anchor, text_box, role) ||
                         target_leftward_property_role(connector, heading, anchor, text_box, role) ||
                         target_property_role(connector, heading, anchor, text_box, role) ||
                         saved_ray_target_property_role(connector, heading, anchor, text_box, role) ||
                         target_diagonal_property_role(connector, heading, anchor, text_box, role) ||
                         target_vertical_role(connector, heading, anchor, text_box, role) ||
                         target_rightward_role(heading, anchor, text_box, role) || text_pos
              if horizontal_aligned_target_baseline?(connector, heading, text_box, role)
                text_pos = [text_pos[0], seat_corner(anchor, text_box)[1] - 7]
              end
              face_multiplicity = if target_left_face_multiplicity?(connector, heading, mult_box, mult,
                                                                    target_face)
                                    directional_multiplicity(:left, anchor, mult_box, mult)
                                  end
              mult_pos = target_multiplicity_seat(connector, heading, anchor, mult_box) ||
                         face_multiplicity || target_horizontal_multiplicity(heading, anchor, mult_box, mult) ||
                         mult_pos
            end

            if end_kind == :source
              text_pos = source_top_property_role(connector, heading, anchor, text_box, role) ||
                         source_bottom_property_role(connector, heading, anchor, text_box, role) || text_pos
              mult_pos = source_top_property_multiplicity(connector, heading, anchor,
                                                          [text_box, mult_box], mult) || mult_pos
              if external_upward_property_source?(connector, heading, anchor, text_box, source_bounds)
                text_pos = external_upward_property_role(anchor, role) || text_pos
              end
            end

            text_box = text_box.merge("alignment" => 1) if phantom_property_box?(connector, direction, text_box)

            if end_kind == :target && !from_property
              bend_positions = target_bend_positions(connector, bend, text_box, mult_box, role)
              text_pos, mult_pos = bend_positions if bend_positions
            end
            if end_kind == :source && !from_property
              stair_positions = source_stair_positions(connector, anchor, text_box, mult_box, role)
              text_pos, mult_pos = stair_positions if stair_positions
            end

            role_bounds = umldi_bounds[end_kind == :source ? :source_role : :target_role]
            mult_bounds = umldi_bounds[end_kind == :source ? :source_multiplicity : :target_multiplicity]
            text_pos = umldi_label_position(role_bounds) if role_bounds
            mult_pos = umldi_label_position(mult_bounds) if mult_bounds
            stereo_pos = umldi_stereotype_position(role_bounds) if stereo && role_bounds

            build_texts(role:, mult:, standalone:,
                        text_pos:, mult_pos:, stereo:, text_box:, stereo_pos:)
          end

          private

          # ALN2 single-line target roles retain their horizontal placement
          # and use the saved corner's baseline on a straight stored ray.
          def horizontal_aligned_target_baseline?(connector, heading, box, role)
            return false unless heading && heading[1].zero? && !heading[0].zero?
            return false unless saved_target_ray?(connector) && !role_empty?(role)
            return false unless connector_source_dest_stereotype(connector, :target).to_s.empty?

            aligned_target_baseline_box?(box)
          end

          def aligned_target_baseline_box?(box)
            return false unless seat_font? && font_weight == 400 && font_style == "normal"
            return false unless box && box["alignment"] == 2 && [13, 14].include?(box["cy"])

            cambria_box?(box.merge("alignment" => 0))
          end

          def plain_leftward_target_role(connector, heading, anchor, box, role)
            return nil unless heading && heading[0].negative? && heading[1].zero?
            return nil unless plain_target_role?(connector, box, role)

            return saved_ray_plain_target_position(anchor, box, role) if moved_plain_target_ray?(connector, box)

            PlainTargetSeat.position(
              connector: connector, anchor: anchor, box: box,
              width: Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            )
          end

          def saved_ray_plain_target_position(anchor, box, role)
            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            x, y = seat_corner(anchor, box)
            [x - width - SEAT_X_INSET, y - 7] if width
          end

          def moved_plain_target_ray?(connector, box)
            saved_target_ray?(connector) && box.values_at("alignment", "cy") == [1, 16] &&
              !stored_offsets_zero?(box)
          end

          def saved_target_ray?(connector)
            connector.connector_type == "Association" &&
              connector.style.to_h.values_at(:mode, :lwidth, :tree, :stored_association_ray) == ["3", "0", nil, true]
          end

          # Moved Property boxes on saved rays arriving from below use the
          # downward seat, relative to the persisted label corner.
          def saved_ray_target_property_role(connector, heading, anchor, box, role)
            return nil unless downward_saved_property?(connector, heading, box)

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            inset, baseline = property_role_offsets(:down)
            [x - inset - width, y + baseline]
          end

          def downward_saved_property?(connector, heading, box)
            heading && heading[1].positive? && heading[1] > heading[0].abs &&
              saved_target_ray?(connector) && moved_target_property_box?(connector, box)
          end

          def plain_target_role?(connector, box, role)
            seat_font? && cambria_box?(box) && !role_empty?(role) &&
              connector_source_dest_stereotype(connector, :target).to_s.empty?
          end

          def plain_leftward_source_role(connector, direction, anchor, box, role)
            return nil unless direction == :left && seat_font? && cambria_box?(box) && !role_empty?(role)
            return nil unless connector_source_dest_stereotype(connector, :source).to_s.empty?

            PlainSourceSeat.position(
              connector: connector, anchor: anchor, box: box,
              width: Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            )
          end

          def source_stair_positions(connector, anchor, text_box, mult_box, role)
            return nil unless seat_font? && cambria_box?(text_box) && cambria_box?(mult_box)
            return nil if role_empty?(role)

            property = property_label?(connector, :source)
            return nil unless property || connector_source_dest_stereotype(connector, :source).to_s.empty?

            SourceStairSeat.positions(
              connector: connector, anchor: anchor, text_box: text_box, mult_box: mult_box,
              width: Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            )
          end

          def target_bend_positions(connector, bend, text_box, mult_box, role)
            return nil unless bend && seat_font? && cambria_box?(text_box) && cambria_box?(mult_box)
            return nil unless connector_source_dest_stereotype(connector, :target).to_s.empty? && !role_empty?(role)

            TargetBendSeat.positions(
              connector: connector, bend: bend, text_box: text_box, mult_box: mult_box,
              width: Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            )
          end

          # With stored boxes on the connector, an end that carries no
          # data of its own draws only its own stereotype; the data end
          # draws the role and multiplicity; with no data anywhere nothing
          # is drawn. Connectors with no stored box keep the opposite-end
          # fallback.
          def own_stereotype_only(text_box, anchor, connector, end_kind)
            stereo = connector_source_dest_stereotype(connector, end_kind)
            pos = position_at(text_box, anchor)
            return [] if stereo.nil? || stereo.empty? || pos.nil?

            [text_at(pos[0], pos[1], "«#{stereo}»")]
          end

          # EA's tree-route label clusters (hand-verified against the
          # EA-published reference, SY 8542 with canvas=(0,0)):
          # source-end pairs stack at the exit point (role +3/-23,
          # mult +3/0); target-end pairs sit just above the dock
          # astride the trunk — role right edge at trunk+7, mult
          # starting at trunk+8, both at dock_y - 8.
          def stored_offsets_zero?(box)
            box["ox"].to_i.zero? && box["oy"].to_i.zero?
          end

          def zero_offset?(text_box, mult_box)
            [text_box, mult_box].compact.all? do |b|
              b["ox"].to_i.zero? && b["oy"].to_i.zero?
            end
          end

          def tree_positions(end_kind, anchor, role, text_pos, mult_pos)
            if end_kind == :source
              [[anchor[0] + 3, anchor[1] - 23],
               [anchor[0] + 3, anchor[1]]]
            else
              width = Ea::Fonts::Metrics.text_length(
                role.to_s, font_size, family: font_family
              ) || role.to_s.length * 6
              [[anchor[0] + 7 - width, anchor[1] - 8],
               [anchor[0] + 8, anchor[1] - 8]]
            end
          end

          # Stored source-end boxes on a 7pt label whose first leg
          # leaves straight up or straight right are seated at the box
          # corner, anchor + (OX, OY) with no sign flip, 3px to its
          # right: the multiplicity 6px above it on an upward leg and
          # 15px below it on a rightward one, the role 7px above it on
          # a rightward one. Other sizes, headings, the target end,
          # custom presentation keep their offsets. Zero multiplicity boxes
          # follow the direction for Cambria and keep the default otherwise.
          def leg_direction(end_kind, heading)
            return nil unless source_seat?(end_kind, heading)

            dx, dy = heading
            return :up if dx.zero? && dy.negative?
            return :right if dy.zero? && dx.positive?
            return :left if dy.zero? && dx.negative?
            return :down if dx.zero? && dy.positive?

            nil
          end

          # Role text on a rightward leg is left-aligned at the corner,
          # 7px above it.
          def role_seat(connector, direction, anchor, box, role)
            return nil unless direction == :right
            return nil if box.nil? || role_empty?(role)
            return nil unless default_presentation?(box)

            x, y = seat_corner(anchor, box)
            [x + SEAT_X_INSET + source_property_centering(connector, direction, box, role), y - 7]
          end

          # Property-role clusters use a direction-specific horizontal seat;
          # alignment controls the stereotype line within that cluster.
          def source_property_seat(connector, direction, anchor, box, role)
            return nil unless source_property_seat?(connector, direction, box)

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            inset, baseline = property_role_offsets(direction)
            left = property_role_x(direction, x, inset + width)
            left = [left, MIN_ROLE_X].max if direction == :up
            left += source_property_centering(connector, direction, box, role)
            [left, y + baseline]
          end

          # Center a short role above the wider stereotype without moving
          # the directional cluster's left edge. Other boxes keep their seat.
          def source_property_centering(connector, direction, box, role)
            return 0 unless centered_property_box?(connector, direction, box)
            return 0 unless seat_font? && font_weight == 400 && font_style == "normal"
            return 0 unless property_label?(connector, :source)

            stereo = "«#{connector_source_dest_stereotype(connector, :source)}»"
            -[stereotype_offset(role, stereo, box.merge("alignment" => 1)), 0].min
          end

          # Measured box heights: left/down Property clusters store CY 35,
          # right-seat clusters CY 31. Phantom outlines leaving down carry a
          # synthesized zero box that centers the same way.
          def centered_property_box?(connector, direction, box)
            cy = { left: 35, down: 35, right: 31 }[direction]
            (cy && box.values_at("cy", "alignment") == [cy, 1]) ||
              (direction == :down && phantom_property_box?(connector, direction, box))
          end

          def source_property_seat?(connector, direction, box)
            phantom_property_box?(connector, direction, box) ||
              (%i[up left right down].include?(direction) &&
                property_role_box?(box, direction, connector.style.to_h) &&
                source_property_font?(connector, direction, box))
          end

          # Phantom outlines carry synthesized zero boxes without alignment.
          # Their default Property cluster uses the directional seat with a
          # centered stereotype; persisted or moved boxes keep their own seat.
          def phantom_property_box?(connector, direction, box)
            %i[up left down].include?(direction) && seat_font? && cambria_box?(box) &&
              box["alignment"].nil? && stored_offsets_zero?(box) &&
              connector.style.to_h[:phantom_outline] == true &&
              property_label?(connector, :source)
          end

          def property_role_x(direction, origin, offset)
            direction == :right ? origin + offset : origin - offset
          end

          # EDGE=1 certifies the top dock independently of the clipped ray's
          # heading. An absent source box uses the upward Property seat.
          def source_top_property_role(connector, heading, anchor, box, role)
            return nil unless source_top_property_box?(connector, heading, box)

            source_property_seat(connector, :up, anchor, box, role)
          end

          def source_top_property_multiplicity(connector, heading, anchor, boxes, mult)
            return nil if mult_empty?(mult)

            role_box, mult_box = boxes
            return nil unless source_top_property_box?(connector, heading, role_box)
            return nil unless source_top_property_box?(connector, heading, mult_box)

            mult_seat(:up, anchor, mult_box)
          end

          def source_top_property_box?(connector, heading, box)
            source_seat?(:source, heading) && heading[0].negative? && heading[1].positive? &&
              zero_source_property_box?(box) && source_top_property_route?(connector.style.to_h) &&
              source_property_seat?(connector, :up, box)
          end

          # A persisted origin above the drawn source outline keeps the
          # upward seat's inset and the shared upper baseline, including
          # steep diagonals. Origins clipped onto the face retain -6.
          def external_upward_property_role(anchor, role)
            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            inset, = property_role_offsets(:up)
            _, baseline = property_role_offsets(:left)
            [[anchor[0] - inset - width, MIN_ROLE_X].max, anchor[1] + baseline]
          end

          def external_upward_property_source?(connector, heading, anchor, box, bounds)
            upward_source_heading?(heading) &&
              zero_source_property_box?(box) && cambria_box?(box) && source_property_cambria?(connector) &&
              external_source_route?(connector, anchor) && above_source_outline?(anchor, bounds)
          end

          def upward_source_heading?(heading)
            source_seat?(:source, heading) && heading[1].negative? && heading[1].abs > heading[0].abs
          end

          def external_source_route?(connector, anchor)
            origin = connector.source_anchor
            connector.connector_type == "Association" && connector.waypoints.size == 3 &&
              connector.style.to_h.values_at(:mode, :lwidth, :tree) == ["3", "0", nil] &&
              connector.label_boxes.to_h.values_at(:llt, :llb).all?(&:nil?) &&
              origin && [origin.x, origin.y] == anchor
          end

          def above_source_outline?(anchor, bounds)
            return false unless bounds&.width&.positive? && bounds.height.positive?

            anchor[1] < bounds.y &&
              anchor[0].between?(bounds.x, bounds.x + bounds.width)
          end

          def zero_source_property_box?(box)
            box && box["alignment"]&.zero? && stored_offsets_zero?(box)
          end

          def source_top_property_route?(style)
            style[:stored_top_dock] == true && style.values_at(:mode, :lwidth, :tree) == ["3", "2", nil]
          end

          # A saved external ray that first meets the source's bottom face
          # seats an absent source Property role like the downward Property
          # seat. The caller reports that face as a downward heading.
          def source_bottom_property_role(connector, heading, anchor, box, role)
            return nil unless source_bottom_dock?(connector, heading, box)

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            inset, baseline = property_role_offsets(:down)
            [x - inset - width, y + baseline]
          end

          def source_bottom_dock?(connector, heading, box)
            source_seat?(:source, heading) && heading[0].zero? && heading[1].positive? &&
              zero_source_property_box?(box) && default_presentation?(box) &&
              source_bottom_property_route?(connector.style.to_h) && source_property_cambria?(connector)
          end

          # A downward leg on the horizontal lateral tree seats an absent
          # box like the up leg already does on the same route.
          def source_bottom_property_route?(style)
            return false unless style.values_at(:mode, :lwidth) == %w[3 2]

            style[:tree] == "LH" || (style[:stored_association_ray] == true && style[:tree].nil?)
          end

          def plain_upward_seat(connector, direction, anchor, box, role)
            return nil unless direction == :up && cambria_box?(box)
            return nil unless [0, 1].include?(box["alignment"])
            return nil unless connector_source_dest_stereotype(connector, :source).empty?
            return nil unless plain_role_route?(connector.style.to_h, box)

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            [x - SEAT_X_INSET - width, y - 6]
          end

          # Moved target Property clusters on horizontal arrivals share
          # the leftward source seat relative to their stored corner.
          def target_leftward_property_role(connector, heading, anchor, box, role)
            return nil unless heading && heading[0].negative? && heading[1].zero?
            return nil unless moved_target_property_box?(connector, box)
            return nil unless horizontal_target_property_route?(connector.style.to_h)

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            [x - property_role_offsets(:left).first - width, y - 7]
          end

          def moved_target_property_box?(connector, box)
            plain_vertical_box?(box) && box["alignment"] == 1 && [31, 35].include?(box["cy"]) &&
              !stored_offsets_zero?(box) && property_label?(connector, :target)
          end

          def horizontal_target_property_route?(style)
            style.values_at(:mode, :lwidth, :tree) == ["3", "0", nil] ||
              (style.values_at(:mode, :lwidth) == %w[3 2] && [nil, "LH"].include?(style[:tree]))
          end

          # An upward target uses the downward property's right edge and
          # the upward target baseline, both relative to its stored corner.
          def target_property_role(connector, heading, anchor, box, role)
            return nil unless upward_target_property?(connector, heading)
            return nil unless plain_vertical_box?(box) && box["alignment"] == 1

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            inset, = property_role_offsets(:down)
            [x - inset - width, y - 7]
          end

          def upward_target_property?(connector, heading)
            heading && heading[0].zero? && heading[1].negative? &&
              property_label?(connector, :target) && downward_property_route?(connector.style.to_h)
          end

          # Zero-offset diagonal labels use the dominant leg's Property
          # right edge. Moved boxes keep their explicit placement.
          def target_diagonal_property_role(connector, heading, anchor, box, role)
            return nil unless diagonal_property_box?(connector, box)

            inset = diagonal_property_inset(heading)
            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family) if inset
            [anchor[0] - inset - width, anchor[1] - 7] if width
          end

          def diagonal_property_box?(connector, box)
            plain_vertical_box?(box) && box["alignment"] == 1 && stored_offsets_zero?(box) &&
              property_label?(connector, :target) &&
              connector.style.to_h.values_at(:mode, :lwidth, :tree) == ["3", "0", nil]
          end

          def diagonal_property_inset(heading)
            return nil unless heading && !heading.include?(0)

            dx, dy = heading
            return property_role_offsets(:left).first if dx.negative? && dx.abs > dy.abs

            property_role_offsets(:down).first if dy.negative? && dy.abs > dx.abs
          end

          def target_vertical_role(connector, heading, anchor, box, role)
            return nil unless heading && heading[0].zero? && !heading[1].zero?

            direction = heading[1].negative? ? :target_up : :target_down
            plain_vertical_role(connector, direction, anchor, box, role)
          end

          # A target whose leg arrives from the right seats its role like a
          # source whose leg leaves to the right.
          def target_rightward_role(heading, anchor, box, role)
            return nil unless heading && heading[1].zero? && heading[0].positive?
            return nil unless seat_font? && cambria_box?(box) && !role_empty?(role)

            x, y = seat_corner(anchor, box)
            [x + SEAT_X_INSET, y - 7]
          end

          def plain_vertical_role(connector, direction, anchor, box, role)
            return nil unless %i[down target_up target_down].include?(direction) &&
                              plain_vertical_box?(box)

            end_kind = direction == :down ? :source : :target
            return nil unless plain_vertical_connector?(connector, end_kind, direction)

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            [x - width - 8, y + (direction == :target_up ? -7 : 15)]
          end

          def plain_vertical_box?(box)
            seat_font? && cambria_box?(box) && [0, 1].include?(box["alignment"])
          end

          # Downward target seats require LV width 2; upward target seats
          # also accept LV width 0. Source seats require a plain width-0 route.
          def plain_vertical_connector?(connector, end_kind, direction)
            return false unless connector.connector_type == "Association" &&
                                connector_source_dest_stereotype(connector, end_kind).empty?

            plain_vertical_style?(connector.style.to_h, direction)
          end

          def plain_vertical_style?(style, direction)
            return false unless style[:mode] == "3"

            if direction == :target_down
              style[:lwidth] == "2" && style[:tree] == "LV"
            elsif direction == :target_up
              style[:lwidth] == "0" && [nil, "LV"].include?(style[:tree])
            else
              style[:lwidth] == "0" && !style[:tree]
            end
          end

          def plain_role_route?(style, box)
            return box["cy"] == 16 if orthogonal_stub_route?(style)

            %w[1 3].include?(style[:mode]) && %w[0 2].include?(style[:lwidth]) &&
              [nil, "V"].include?(style[:tree])
          end

          def property_role_box?(box, direction, style = {})
            return false unless box && default_presentation?(box)
            return [0, 1].include?(box["alignment"]) unless direction == :down

            case box["alignment"]
            when 1 then true
            when 0 then persisted_plain_down_box?(box, style)
            else false
            end
          end

          # Persisted alignment-0 boxes on untreed routes use the downward
          # seat, including saved rays; the "OS" route also seats absent boxes.
          def persisted_plain_down_box?(box, style)
            return true if orthogonal_stub_route?(style)

            !stored_offsets_zero?(box) && style[:tree].nil?
          end

          def property_role_offsets(direction)
            case direction
            when :up then [60, -6]
            when :left, :right then [60, -7]
            else [65, 15]
            end
          end

          def source_property_font?(connector, direction, box)
            source_property_cambria?(connector) &&
              source_property_route?(connector.style.to_h, direction, box)
          end

          def source_property_cambria?(connector)
            font_family.to_s.casecmp("Cambria").zero? && property_label?(connector, :source)
          end

          def source_property_route?(style, direction, box)
            case direction
            when :right then style.values_at(:mode, :lwidth, :tree) == %w[3 2 H]
            when :up then upward_property_route?(style)
            when :left then orthogonal_stub_route?(style) || left_property_route?(style)
            else downward_source_route?(style, box)
            end
          end

          def downward_source_route?(style, box)
            [orthogonal_stub_route?(style), lateral_horizontal_route?(style), mode_two_route?(style),
             downward_property_route?(style), persisted_width_zero_down_box?(box, style),
             centered_width_zero_down_box?(box, style)].any?
          end

          def persisted_width_zero_down_box?(box, style)
            box["alignment"]&.zero? && !stored_offsets_zero?(box) && style[:stored_association_ray] != true &&
              style.values_at(:mode, :lwidth, :tree) == ["3", "0", nil]
          end

          def centered_width_zero_down_box?(box, style)
            box["alignment"] == 1 && stored_offsets_zero?(box) && style[:stored_association_ray] != true &&
              style.values_at(:mode, :lwidth, :tree) == ["3", "0", nil]
          end

          # Mode 3, width 2 on the horizontal lateral tree.
          def lateral_horizontal_route?(style)
            style.values_at(:mode, :lwidth, :tree) == %w[3 2 LH]
          end

          # Mode 2, width 2 without a tree seats like the other width-2 modes.
          def mode_two_route?(style)
            style.values_at(:mode, :lwidth, :tree) == ["2", "2", nil]
          end

          def upward_property_route?(style)
            return orthogonal_stub_route?(style) if style[:tree] == "OS"

            %w[0 2].include?(style[:lwidth])
          end

          # The "OS" route seats its Property roles at the same directional
          # corner seats as the untreed width-2 route.
          def orthogonal_stub_route?(style)
            style.values_at(:mode, :lwidth, :tree) == %w[3 2 OS]
          end

          def left_property_route?(style)
            downward_property_route?(style) || mode_two_route?(style) ||
              (style[:overlap_ray] == true && style.values_at(:mode, :lwidth, :tree) == ["2", "0", nil]) ||
              (style[:mode] == "3" && %w[0 2].include?(style[:lwidth]) &&
                [nil, "H", "LV"].include?(style[:tree]))
          end

          def downward_property_route?(style)
            %w[1 3].include?(style[:mode]) && style[:lwidth] == "2" && !style[:tree]
          end

          def directional_multiplicity(direction, anchor, box, mult)
            return nil unless cambria_box?(box)

            x, y = seat_corner(anchor, box)
            return [x + 8, y + 15] if direction == :down
            return nil unless direction == :left

            width = Ea::Fonts::Metrics.text_length(mult, font_size, family: font_family)
            [x - width - 3, y + 15] if width
          end

          # On an "H" tree route a property end leaving right seats its
          # multiplicity one text width further right than the plain
          # rightward seat.
          def horizontal_tree_multiplicity(connector, direction, anchor, box, mult)
            return nil unless direction == :right && property_label?(connector, :source)
            return nil unless connector.style.to_h[:tree] == "H" && cambria_box?(box) && !mult_empty?(mult)

            width = Ea::Fonts::Metrics.text_length(mult, font_size, family: font_family)
            x, y = seat_corner(anchor, box)
            [x + SEAT_X_INSET + width, y + 15] if width
          end

          # An absent source box on a leftward tree leg seats a Property role
          # at the leftward Property seat, not the rightward tree default.
          def tree_left_property_role(connector, end_kind, heading, anchor, box, role)
            return nil unless leg_direction(end_kind, heading) == :left && box&.[]("alignment")&.zero?
            return nil unless connector.style.to_h.values_at(:mode, :lwidth) == %w[3 2]

            source_property_seat(connector, :left, anchor, box, role)
          end

          # A tree-route source leaving left seats its multiplicity like any
          # other leftward source rather than at the rightward tree default.
          def tree_left_multiplicity(end_kind, heading, anchor, box, mult)
            return nil if end_kind != :source || mult_empty?(mult) || leg_direction(end_kind, heading) != :left

            directional_multiplicity(:left, anchor, box, mult)
          end

          # A target whose first leg runs sideways seats its multiplicity at
          # the stored corner like a source leaving the same way.
          def target_horizontal_multiplicity(heading, anchor, box, mult)
            return nil unless seat_font? && heading && heading[1].zero? && !heading[0].zero?
            return nil if mult_empty?(mult)

            return directional_multiplicity(:left, anchor, box, mult) if heading[0].negative?

            mult_seat(:right, anchor, box)
          end

          def target_left_face_multiplicity?(connector, heading, box, mult, target_face)
            seat_font? && !mult_empty?(mult) && property_label?(connector, :target) && cambria_box?(box) &&
              stored_offsets_zero?(box) && target_left_face_heading?(heading, target_face)
          end

          def target_left_face_heading?(heading, target_face)
            heading && !heading[1].zero? && heading[0].negative? && target_face == [-1, 0]
          end

          def target_multiplicity_seat(connector, heading, anchor, box)
            return nil unless seat_font?
            return nil unless heading && heading[0].zero? && heading[1].negative?
            return nil unless target_multiplicity_box?(connector, box)

            x, y = seat_corner(anchor, box)
            [x + 8, y - 7]
          end

          def target_multiplicity_box?(connector, box)
            # Property targets seat at the stored corner; plain moved labels
            # retain their explicit offsets.
            cambria_box?(box) && (stored_offsets_zero?(box) || property_label?(connector, :target))
          end

          def cambria_box?(box)
            box && default_presentation?(box) && font_family.to_s.casecmp("Cambria").zero?
          end

          def mult_seat(direction, anchor, box)
            return nil unless %i[up right].include?(direction)
            return nil if box.nil?
            return nil if stored_offsets_zero?(box) && !cambria_box?(box)
            return nil unless default_presentation?(box)

            x, y = seat_corner(anchor, box)
            [x + SEAT_X_INSET, direction == :right ? y + 15 : y - 6]
          end

          def source_seat?(end_kind, heading)
            end_kind == :source && heading && seat_font?
          end

          def seat_font?
            font_size == SEAT_FONT_SIZE && font_unit == "pt"
          end

          # Boxes with explicit string-keyed OX/OY (the QEA shape) that
          # are unrotated, unhidden, unstyled and left/center aligned.
          def default_presentation?(box)
            return false unless box["ox"] && box["oy"]
            return false unless [nil, 0, 1].include?(box["alignment"])
            return false unless [nil, -1].include?(box["color"])

            box["rotation"].to_i.zero? && box["direction"].to_i.zero? &&
              box.values_at("hidden", "bold", "italic", "underline")
                 .none?
          end

          def seat_corner(anchor, box)
            [anchor[0] + box["ox"].to_i, anchor[1] + box["oy"].to_i]
          end

          def build_texts(role:, mult:, standalone:, text_pos:, mult_pos:,
                          stereo:, text_box:, stereo_pos: nil)
            if role && !role.empty? && text_pos
              x, y = text_pos
              texts = [text_at(x, y, role)]
              if stereo
                stereo_x, stereo_y = stereo_pos || [x + stereotype_offset(role, stereo, text_box),
                                                    y + property_y_offset(text_box)]
                texts << text_at(stereo_x, stereo_y, stereo)
              end
              if mult && !mult.empty? && mult_pos
                texts << text_at(*mult_pos, mult)
              end
              texts
            elsif standalone && !standalone.empty? && mult_pos
              [text_at(*mult_pos, standalone)]
            else
              []
            end
          end

          def umldi_label_position(bounds)
            [bounds[:x], bounds[:y] + font_pixel_size.ceil]
          end

          def umldi_stereotype_position(bounds)
            [bounds[:x], bounds[:y] + font_pixel_size.ceil + (font_pixel_size.ceil + 2)]
          end

          def font_pixel_size
            font_unit == "pt" ? font_size * 4.0 / 3 : font_size
          end

          def stereotype_offset(role, stereo, text_box)
            return 0 unless text_box && text_box["alignment"] == 1

            role_width = TextRenderer.estimate_width(role, font_size,
                                                     family: font_family).round
            stereo_width = TextRenderer.estimate_width(stereo, font_size,
                                                       family: font_family).round
            ((role_width - stereo_width) / 2.0).round
          end

          # EA renders «Property» between role name and multiplicity
          # exactly on connector ends carrying
          # t_connector.SourceStereotype / DestStereotype = "Property"
          # (case-insensitive; stored variants include "property").
          # Direction does not decide — Fig 11's directed aggregations
          # carry no end stereotype and render none, while the CityGML
          # profile diagrams mark ends explicitly.
          PROPERTY_KEYWORD = "property"

          def connector_source_dest_stereotype(connector, end_kind)
            stereo = end_kind == :source ? connector.source_stereotype :
                       connector.target_stereotype
            stereo.to_s.strip
          end

          def property_label?(connector, end_kind)
            stereo = end_kind == :source ? connector.source_stereotype : connector.target_stereotype
            stereo.to_s.downcase == PROPERTY_KEYWORD
          end

          def role_empty?(role)
            role.nil? || role.empty?
          end

          def mult_empty?(mult)
            mult.nil? || mult.empty?
          end

          def opposite(end_kind)
            end_kind == :source ? :target : :source
          end

          def role_and_multiplicity(connector, end_kind)
            assoc = association_for(connector)
            return [nil, nil, nil] unless assoc

            prop = property_at_end(assoc, end_kind, connector)
            return [true, *property_role(prop)] if prop

            [false, *association_role(assoc, end_kind)]
          end

          def property_at_end(association, end_kind, connector = nil)
            # EA renders the source classifier's synthesized
            # association-end property (matched by the connector's
            # relationship guid), falling back to the property index
            # lookup by association source/target id.
            if connector&.relationship_ref
              prop = placed_end_property(association, end_kind, connector.relationship_ref)
              return prop if prop
            end

            id = end_kind == :source ? association.source_id : association.target_id
            return nil unless id

            return document.property_by_id(id) if document

            fallback_property_lookup(id)
          end

          def placed_end_property(association, end_kind, relationship_ref)
            placed = placed_classifier_id(association, end_kind)
            property = assoc_end_property(placed, relationship_ref)
            property unless property && opposite_role_property?(association, end_kind, property)
          end

          # A UML attribute belongs to the classifier opposite its role.
          # Do not draw that same role again at its anonymous owner end.
          def opposite_role_property?(association, end_kind, property)
            own = end_kind == :source ? association.source_role_name : association.target_role_name
            other = end_kind == :source ? association.target_role_name : association.source_role_name
            role_empty?(own) && other == property.name
          end

          def placed_classifier_id(association, end_kind)
            end_kind == :source ? association.source_id : association.target_id
          end

          # Named association-end properties carry typed labels. Unnamed
          # XMI member-end references defer to the saved association role
          # and cardinality; direct property-id endpoints are resolved above.
          def assoc_end_property(classifier_id, relationship_ref)
            return nil unless classifier_id

            classifier = model_index[classifier_id]
            return nil unless classifier.is_a?(Ea::Model::Classifier)

            (classifier.properties || []).find do |p|
              p.association_id == relationship_ref && !p.name.to_s.empty?
            end
          end

          # Linear-scan fallback for callers that did not wire in
          # the Document. Production paths go through Document's
          # property_index for O(1) lookup.


          def fallback_property_lookup(id)
            return nil unless model_index

            model_index.each_value do |obj|
              next unless obj.is_a?(Ea::Model::Classifier)

              found = (obj.properties || []).find { |p| p.id == id }
              return found if found
            end
            nil
          end

          def property_role(property)
            visibility = visibility_prefix(property)
            name = property.name.to_s
            type_name = property.type_name.to_s
            line = if type_name.empty? || type_name == " "
                     "#{visibility}#{name}"
                   else
                     "#{visibility}#{name}: #{namespace_double_colon(type_name)}"
                   end
            role = line.empty? ? nil : line
            mult = multiplicity_text(property)
            [role, mult]
          end

          def namespace_double_colon(type_name)
            return type_name if type_name.nil? || type_name.empty?

            type_name.to_s.gsub(/([A-Za-z0-9_]):([A-Za-z])/, '\1::\2')
          end

          def association_role(assoc, end_kind)
            name = end_kind == :source ? assoc.source_role_name : assoc.target_role_name
            raw = end_kind == :source ? assoc.source_multiplicity_raw : assoc.target_multiplicity_raw
            lower = end_kind == :source ? assoc.source_multiplicity_lower : assoc.target_multiplicity_lower
            upper = end_kind == :source ? assoc.source_multiplicity_upper : assoc.target_multiplicity_upper
            mult = raw && !raw.empty? ? raw : multiplicity_string(lower, upper)
            return [nil, mult] if name.to_s.include?("::")

            role = name.nil? || name.empty? ? nil : "+#{name}"
            [role, mult]
          end

          def association_for(connector)
            return nil unless model_index

            rel = model_index[connector.relationship_ref]
            return nil unless rel.is_a?(Ea::Model::Association)

            rel
          end

          # Returns the aggregation kind for the given end (:shared,
          # :composite, or nil). An aggregation marker on the OPPOSITE
          # end means THIS end is the "part" end of an aggregation —
          # EA shows "1" multiplicity for such ends.
          def aggregation_kind_for(connector, end_kind)
            assoc = association_for(connector)
            return nil unless assoc

            opposite_kind = opposite(end_kind)
            agg = opposite_kind == :source ? assoc.source_aggregation : assoc.target_aggregation
            return nil if agg.nil? || agg == "none"

            agg.to_sym
          end

          def position_at(box, anchor)
            return nil unless box

            offset_x = box["ox"] || box[:ox]
            offset_y = box["oy"] || box[:oy]
            return nil if offset_x.nil? && offset_y.nil?

            # Waypoint anchors are mirrored to screen-down space; the
            # stored OY offset counts the other way, so negate it.
            [anchor[0] + offset_x.to_i, anchor[1] - offset_y.to_i]
          end

          # The stereotype line sits 12px below the role on 7pt labels
          # with default presentation;
          # other sizes and custom presentation keep size + 6.
          def property_y_offset(text_box)
            return SEAT_STEREOTYPE_GAP if seat_font? && text_box &&
                                          default_presentation?(text_box)

            font_size + 6
          end

          def multiplicity_text(property)
            raw = property.multiplicity_raw
            return raw if raw && !raw.empty?

            multiplicity_string(property.multiplicity_lower,
                                property.multiplicity_upper)
          end

          def multiplicity_string(lower, upper)
            return nil if lower.nil? && upper.nil?
            return "1" if lower == 1 && upper == 1

            upper_str = upper == -1 ? "*" : upper.to_s
            "#{lower || 0}..#{upper_str}"
          end

          # EA suppresses standalone multiplicity when it is
          # unspecified (nil). Explicit multiplicity renders
          # regardless of aggregation kind. The QEA parser now
          # returns nil for absent SourceCard/DestCard so default
          # "1" is no longer produced — only explicit "1" reaches
          # this method.
          def standalone_multiplicity(role, mult, aggregation: nil)
            return nil if role && !role.empty?
            return nil if mult.nil?

            mult
          end

          def visibility_prefix(property)
            VisibilitySymbol.for(property.visibility)
          end

          def text_at(x, y, content)
            return nil if content.nil? || content.empty?

            x_t = canvas ? canvas.translate_x(x) : x
            y_t = canvas ? canvas.translate_y(y) : y
            TextRenderer.new(content:, x: x_t, y: y_t,
                             family: font_family, size: font_size,
                             weight: font_weight, style: font_style,
                             size_unit: font_unit,
                             fill: fill_color).to_svg
          end

          def fill_color
            "#000000"
          end
        end
      end
    end
  end
end
